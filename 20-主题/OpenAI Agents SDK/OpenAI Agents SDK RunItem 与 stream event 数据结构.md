---
tags:
  - 主题
  - OpenAI Agents SDK
  - RunItem
  - streaming
  - 源码
type: note
---

# OpenAI Agents SDK RunItem 与 stream event 数据结构

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 在 `items.py`、`run_internal/items.py`、`stream_events.py` 和 `run_internal/streaming.py` 里定义的一层中间数据模型。

如果只看 `Response` 或最终字符串输出，很容易忽略运行时中间其实维护了一套更稳定的对象面：

- `RunItem`
- `RunItemStreamEvent`
- `RawResponsesStreamEvent`
- `AgentUpdatedStreamEvent`

这层决定了模型输出怎样被归类、怎样回放进下一轮、怎样持久化进 session，以及 streaming 模式到底向外发什么。

## 为什么重要

- `RunItem` 是 SDK 内部真正拿来串 turn、tool、handoff、session 和 resume 的公共载体
- streaming 看到的不是单纯 token 流，还包括运行时自己派生出来的 item 事件
- 只有理解这层，才容易解释为什么有些对象能 replay 回模型，有些对象只能留在本地运行时

## `RunItemBase` 为什么是统一包装层

`items.py` 里的 `RunItemBase` 可以先理解成“给 Responses item 套一层运行时语义”。

它至少统一了几件事：

- 记录这个 item 属于哪个 `agent`
- 保存原始 `raw_item`
- 提供 `to_input_item()`，把 item 重新变成下一轮可发送给模型的输入
- 用 weak reference 处理 agent 引用，避免结果对象长期强持有整棵 agent 图

所以 `RunItem` 不是另一份业务数据，而是“可继续参与运行时编排的 item 表示”。

## `RunItem` 为什么不是一个类，而是一组联合类型

`RunItem` 是一个 type alias，里面包含多种 item：

- `MessageOutputItem`
- `ToolSearchCallItem`
- `ToolSearchOutputItem`
- `HandoffCallItem`
- `HandoffOutputItem`
- `ToolCallItem`
- `ToolCallOutputItem`
- `ReasoningItem`
- `MCPListToolsItem`
- `MCPApprovalRequestItem`
- `MCPApprovalResponseItem`
- `CompactionItem`
- `ToolApprovalItem`

这说明 SDK 内部并不只把“模型说的话”当历史，而是把工具调用、工具结果、handoff、approval、compaction 都纳入统一 item 流。

## 为什么不同 `RunItem` 的职责并不对称

这一层最容易搞混的是：这些 item 都叫 `RunItem`，但它们的运行时角色不一样。

可以先这样记：

- `MessageOutputItem`：模型最终可读文本消息
- `ToolCallItem`：模型发出的工具调用
- `ToolCallOutputItem`：工具执行后回送给模型的结果
- `HandoffCallItem`：模型发出的 handoff 调用
- `HandoffOutputItem`：运行时确认 handoff 已发生后的内部记录
- `ReasoningItem`：模型 reasoning item 的包装
- `ToolApprovalItem`：需要人工审批的中断占位，不是普通历史

这里最关键的一点是：`ToolApprovalItem` 和普通 item 不同，它不是“下一轮继续发给模型”的历史片段，而是“运行时暂停点”。

## `to_input_item()` 为什么暴露了 replay 边界

`RunItem` 是否能安全回放给模型，主要看它的 `to_input_item()`。

### 大多数 item 可以直接 replay

`RunItemBase.to_input_item()` 的默认行为很简单：

- `dict` 直接返回
- Pydantic model 用 `model_dump(exclude_unset=True)` 转回输入 item

这意味着大部分 Responses output item 都可以被重新整理成下一轮输入。

### 某些工具 item 会先去掉 output-only 字段

例如 tool search item 会清掉：

- `created_by`

tool output replay 时也会剥掉运行时 bookkeeping 字段，例如 `shell_call_output` 里的：

- `status`
- `shell_output`
- `provider_data`

这说明运行时内部为了执行和展示保留的信息，不一定是 Responses API 下一轮还能接受的输入。

### `ToolApprovalItem` 明确不能 replay

`ToolApprovalItem.to_input_item()` 直接抛异常。

`run_internal/items.py` 的 `run_item_to_input_item()` 和 `run_items_to_input_items()` 也会显式跳过：

- `tool_approval_item`

这条规则非常重要，因为它把“可继续对模型可见的历史”和“只属于运行时控制流的中断对象”清楚分开了。

## `turn_resolution` 为什么是分类入口

`turn_resolution.py` 里真正做分类的地方，决定了模型输出进入运行时后会落到哪种 item。

典型映射包括：

- `ResponseOutputMessage` -> `MessageOutputItem`
- `ResponseReasoningItem` -> `ReasoningItem`
- 各类工具调用 -> `ToolCallItem`
- 命中 handoff 名称的函数调用 -> `HandoffCallItem`
- `McpApprovalRequest` -> `MCPApprovalRequestItem`
- `McpApprovalResponse` -> `MCPApprovalResponseItem`

这意味着 `RunItem` 不是静态 schema，而是运行时对模型输出做完解释后的分类结果。

## streaming 模式为什么有三层事件面

`stream_events.py` 里对外暴露的流式事件只有三类：

- `RawResponsesStreamEvent`
- `RunItemStreamEvent`
- `AgentUpdatedStreamEvent`

它们分别对应不同层级：

### `RawResponsesStreamEvent`

直接包裹底层 `ResponseStreamEvent`，最接近模型原始流。

### `RunItemStreamEvent`

当 SDK 已经把模型输出加工成 `RunItem` 后，`run_internal/streaming.py` 会把这些 item 映射成更稳定的事件名，例如：

- `message_output_created`
- `handoff_requested`
- `handoff_occured`
- `tool_called`
- `tool_output`
- `reasoning_item_created`
- `mcp_approval_requested`

这里最值得记的是：它更像固定投影表，而不是对 raw event subtype 的一比一透传。

### `AgentUpdatedStreamEvent`

handoff 发生后，流式事件流里不仅有“产生了什么 item”，还有“现在是谁在跑”。

这说明 streaming 看到的不只是内容流，还有运行时角色变化。

## 为什么 `ToolApprovalItem` 不会进入普通流式事件

`run_internal/streaming.py` 里对 `ToolApprovalItem` 的处理很特别：

- 它不会生成 `RunItemStreamEvent`
- 注释直接写明 approvals 是 interruption，不是 streamed item

这和前面的 replay 规则是一致的。

也就是说，approval 在这套 SDK 里同时具备两个边界：

- 不能当作普通历史 replay 给模型
- 不能当作普通 item 事件持续往外流

它更像控制流里的暂停标记。

## `run_internal/items.py` 为什么是续跑边界层

这一层除了简单转换，还有几条很关键的续跑规则：

- 会主动丢掉 orphan tool calls
- reasoning item 的 `id` 可以按策略移除
- 内部元数据会在 replay 前清理

这说明真正送回下一轮模型的输入，并不是“把现有 item 原样再喂一次”，而是经过运行时裁剪和清洗之后的结果。

## 一个具体场景怎么理解这层

如果一次 run 里既发生了工具调用，也发生了 handoff，还夹着 approval 中断，那么 SDK 内部真正共享的“公共语言”并不是最终字符串输出，而是这些中间 `RunItem`。

它们让系统能同时处理：

- streaming
- session 持久化
- interruption / resume
- handoff 输入迁移

这个场景能帮助我记住：`RunItem` 最重要的价值，不是好看，而是可编排。

## 最该记住的点

- `RunItem` 是运行时公共载体，不只是输出包装
- 不同 `RunItem` 的职责并不对称，尤其 `ToolApprovalItem` 更偏控制流
- streaming 里除了 raw event，还有 SDK 自己派生的语义事件
- replay 给模型之前会有明确的清洗和裁剪边界

## 易错点

- 容易把 `RunItem` 当成单纯输出包装
- 容易把所有 `RunItem` 看成对称对象
- 容易把 streaming 理解成只有 raw token/event
- 容易忽略 input replay 前的清洗步骤，误以为 `raw_item` 一定能原样回送给模型

## 我的理解

OpenAI Agents SDK 在这一层做的事情，不只是“定义几种消息类型”，而是把模型输出、运行时控制流和可续跑历史压进同一套中间表示。

所以 `RunItem` 最重要的价值不是名字统一，而是它让工具执行、handoff、approval、streaming 和 session 之间能够说同一种语言。

## 相关笔记

- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK handoff 交接语义与输入迁移]]
