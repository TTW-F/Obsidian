---
tags:
  - 主题
  - OpenAI Agents SDK
  - handoff
  - 多智能体
  - 源码
type: note
---

# OpenAI Agents SDK handoff 交接语义与输入迁移

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 里的 handoff 机制，以及一次 handoff 真正发生时，运行时如何处理三件事：

- handoff 在模型侧如何被暴露
- handoff 到下一位 agent 时如何执行交接
- 交接后下一位 agent 到底会看到什么输入

如果只看高层文档，很容易把 handoff 理解成“多 agent 之间跳一下”；但从 `src/agents/handoffs/` 和 `run_internal/turn_resolution.py` 看，它其实是一套带有 tool 语义、输入迁移规则和历史重写能力的交接协议。

## 为什么重要

- handoff 不是简单分支跳转，而是运行时里一种会改变后续处理者的动作
- 这层直接决定多 agent 工作流里“下一位 agent 接手时能看到什么”
- 如果想理解为什么 OpenAI Agents SDK 的多 agent 不只是“agent A 调 agent B”，handoff 是最直接的落点

## handoff 在模型侧是什么

文档和 `src/agents/handoffs/__init__.py` 都很明确：handoff 会作为 tool 暴露给模型。

默认情况下，tool name 来自：

- `Handoff.default_tool_name(agent)`

例如类似：

- `transfer_to_refund_agent`

tool description 则来自：

- `Handoff.default_tool_description(agent)`

这意味着从模型的视角看，handoff 不是隐藏控制流，而是一个可选工具调用面。

## `handoff()` helper 真正固定了什么

`handoff()` 这个 helper 的核心特点是：

- 它总是绑定到一个明确的目标 agent
- `on_handoff` 只负责副作用或记录，不负责改目标

这点很重要，因为它说明 OpenAI Agents SDK 的推荐模式不是“运行时里再动态返回另一个 agent”，而是：

- 为每个候选专家显式注册一个 handoff
- 让模型在这些 handoff tool 之间选择

## `input_type` 为什么不是下一位 agent 的主输入

`handoff()` 还支持：

- `input_type`
- `on_handoff`

这两者组合后的语义是：

- 模型在调用 handoff tool 时，可以顺带生成一小段结构化元数据
- SDK 会先按 `input_type` 校验这段 JSON
- 再把解析后的结果传给 `on_handoff`

但这段 payload 不是下一位 agent 的主输入。

它更像交接元数据，例如：

- reason
- language
- priority
- summary

这也是 handoff 和真正“改写下一个 agent 看见的历史”之间最容易混淆的一点。

## `HandoffInputData` 为什么是输入迁移核心对象

`handoffs/__init__.py` 里的 `HandoffInputData` 很值得重点看。

它把交接时涉及的输入拆成了几块：

- `input_history`
- `pre_handoff_items`
- `new_items`
- `run_context`
- `input_items`

这个拆法很关键，因为它说明 handoff 不是简单地把“当前 transcript 全量传下去”。

运行时区分了：

- run 开始前的历史
- 本轮 handoff 发生前已经生成的 items
- 当前轮新生成的 items
- 专门给下一个 agent 的输入 items

所以 handoff 输入迁移是结构化处理，不是字符串拼接。

## `input_filter` 真正决定了什么

`Handoff.input_filter` 是 handoff 最有辨识度的地方之一。

它拿到的是完整的 `HandoffInputData`，返回的也是新的 `HandoffInputData`。

这意味着它不是一个简单文本过滤器，而是可以同时改：

- 历史
- pre-handoff items
- new items
- input_items

特别值得记住的是：

- `new_items` 可以继续保留给 session history
- `input_items` 可以单独作为下一位 agent 的模型输入

也就是说，OpenAI Agents SDK 明确支持“会话里保留完整轨迹，但给下一位 agent 的输入做裁剪”。

## `nest_handoff_history` 为什么更像专用上下文收缩

`handoffs/history.py` 里提供的 `nest_handoff_history()`，不是彻底过滤历史，而是把之前 transcript 折叠成一条 assistant summary message。

它会：

- 先把历史和当前 items 变成 plain inputs
- 把工具和 side-effect 项做去重 / 裁剪
- 再包装成带 `<CONVERSATION HISTORY>` 标记的摘要消息

这个机制的重点不是“精确保留每一条原始 item”，而是：

- 把前情摘要化
- 把重复的工具 / 推理 item 从直接输入里剔掉
- 让 handoff 后的上下文更短、更干净

所以 `nest_handoff_history` 更像 handoff 专用的上下文收缩策略。

## `execute_handoffs()` 为什么是真正的运行时交接入口

`run_internal/turn_resolution.py` 里的 `execute_handoffs()` 很值得重点看。

它真正做的事情包括：

- 处理多 handoff 冲突
- 调用 `handoff.on_invoke_handoff(...)`
- 写入 handoff output item
- 触发 hooks
- 应用 `input_filter`
- 应用 `nest_handoff_history`
- 最终返回 `NextStepHandoff(new_agent)`

这说明 handoff 在运行时里不是单点动作，而是一整次交接流程。

## server-managed conversation 为什么会限制输入重写

`turn_resolution.py` 里还有一个很重要的限制逻辑：

- 如果启用了 server-managed conversations
- 明确的 handoff input filter 不被支持
- nested handoff history 也会被关闭并给出 warning

这说明 handoff 的输入迁移能力并不是在所有会话模式下都完全自由的。

只要上下文管理更多交给 server 侧，runner 对 handoff 输入的本地重写空间就会缩小。

## 一个具体场景怎么理解 handoff

如果一个 routing agent 把用户请求交给专门的 refund agent，那么真正发生的不是“换个 agent 名字继续跑”，而是：

- 模型先调用 handoff tool
- 运行时记录交接结果
- 可选传入结构化交接元数据
- 再决定下一位 agent 的输入历史是否要裁剪、折叠或重写

这个场景能帮助我记住：handoff 本质上不是跳转语法，而是一套交接协议。

## 最该记住的点

- handoff 在模型侧先表现成一个 tool
- `input_type` 只是 handoff tool payload，不是下一位 agent 的主输入
- `input_filter` 和 `input_items` 让“会话历史”和“模型输入”可以显式分开
- `execute_handoffs()` 才是真正的运行时交接入口

## 易错点

- 容易把 handoff 理解成普通工具调用，但它会改变后续处理者和输入上下文
- 容易把 `input_type` 误解成下一位 agent 的主输入
- 容易忽略 `input_filter` 和 `input_items` 的区别
- 容易以为 nested handoff history 永远可用，而忽略 server-managed conversation 下的限制

## 我的理解

OpenAI Agents SDK 的 handoff 最值得学的地方，不是“支持多 agent”，而是它把交接这件事拆成了三层：

- 模型侧：handoff 是一个可选 tool
- 运行时侧：handoff 是一种 `NextStep`
- 输入侧：handoff 允许显式重写下一位 agent 看见的历史

所以这套 handoff 机制本质上不是跳转语法，而是一套交接协议。

## 相关笔记

- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK tracing 结构与 span 语义]]
