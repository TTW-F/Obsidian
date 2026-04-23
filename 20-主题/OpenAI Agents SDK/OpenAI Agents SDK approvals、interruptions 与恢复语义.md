---
tags:
  - 主题
  - OpenAI Agents SDK
  - approvals
  - interruption
  - resume
  - 源码
type: note
---

# OpenAI Agents SDK approvals、interruptions 与恢复语义

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 里“工具审批导致中断，再基于状态恢复继续执行”的那条运行时主线。

它关心的不是“界面上怎么点批准”，而是 SDK 在内部怎样表示审批请求、保存审批决定、把 run 暂停下来，以及之后怎样继续往下跑。

## 为什么重要

- 这套 SDK 不是简单地在工具执行前弹窗，而是把 approval 设计成正式的运行时状态
- interruption 之后不是整轮重来，而是带着已有历史、审批记录和处理中间态继续推进
- 如果不理解这层，很容易误判为什么同一个工具有时直接执行，有时进入 `interruptions`

## `ToolApprovalItem` 为什么是暂停点而不是普通输出

`items.py` 里的 `ToolApprovalItem` 是 approval 语义的核心载体。

它至少携带这些信息：

- `raw_item`
- `tool_name`
- `tool_namespace`
- `tool_origin`
- `tool_lookup_key`
- `call_id`
- `arguments`

这说明审批对象不是抽象的“一个确认动作”，而是对某一次具体工具调用的结构化包装。

更关键的是：

- 它继承 `RunItemBase`
- 但 `to_input_item()` 会直接抛异常

也就是说，审批对象虽然进入了运行时 item 体系，但它从一开始就被定义成“不可 replay 给模型”的特殊 item。

## 审批决定到底存在哪里

`run_context.py` 里的 `RunContextWrapper` 维护了 `_approvals` 字典，值是 `_ApprovalRecord`。

`_ApprovalRecord` 里保存的不是单一布尔值，而是更细的结构：

- `approved`
- `rejected`
- `rejection_messages`
- `sticky_rejection_message`

其中 `approved` / `rejected` 既可能是：

- `True` / `False` 这种永久决定
- 也可能是某组 `call_id` 列表，表示只对特定调用生效

这意味着 SDK 内部原生支持两种审批粒度：

- 这一次调用是否允许
- 以后这个工具是否一直允许或一直拒绝

## approval key 为什么不是简单工具名

这层有一个很工程化的细节：审批状态不是只按 `tool_name` 记录。

`RunContextWrapper` 会结合这些信息推导 approval key：

- `tool_name`
- `tool_namespace`
- `tool_lookup_key`
- bare name alias
- legacy deferred key

而这一套 key 规则又会和 `_tool_identity.py` 协同。

这件事的重要性在于：namespaced tool、deferred-loading tool、同名工具的不同 wire shape 不能只靠裸工具名区分，否则 approve / reject 很容易串台。

## interruption 为什么是结果对象的一部分

`result.py` 里 `RunResult` 和 `RunResultStreaming` 都有：

- `interruptions: list[ToolApprovalItem]`

所以 approval 不是临时异常分支，而是正式挂在结果对象上的运行时状态。

这也解释了典型用法为什么是：

1. 先跑到 `result.interruptions`
2. `result.to_state()`
3. 在 `state` 上 approve / reject
4. 再把 `state` 送回 `Runner.run()` 或 `Runner.run_streamed()`

## `to_state()` 为什么是恢复语义的关键

`RunResult.to_state()` 和 `RunResultStreaming.to_state()` 都会把当前运行结果转成 `RunState`。

这里保留下来的不仅是新 items，还包括：

- `last_processed_response`
- `current_turn`
- `current_turn_persisted_item_count`
- `tool_use_tracker_snapshot`
- `conversation_id`
- `previous_response_id`
- `reasoning_item_id_policy`
- `interruptions`
- trace state
- sandbox resume state

而 `_populate_state_from_result()` 会在发现有 `interruptions` 时，把状态的下一步设成：

- `NextStepInterruption(interruptions=...)`

这说明恢复不是“重新分析历史后猜测怎么继续”，而是把暂停点明确编码进状态机。

## 恢复为什么不是“重新跑整轮模型”

这套 SDK 最值得重点记住的一点是：approval 之后的 resume，并不是把整轮模型再请求一遍。

更接近实际的做法是：

- 读取上一次中断前最后一份 model response
- 读取已经构建好的 `processed_response`
- 根据当前 approval table、已有 outputs 和 pending items，继续走工具侧后半段

所以恢复的重点不是“再问模型一次”，而是“从已经确定过的工具计划继续执行”。

## fresh turn 和 resume turn 为什么要分开处理

`run_internal/tool_planning.py` 里专门分了两套计划构建：

- `_build_plan_for_fresh_turn()`
- `_build_plan_for_resume_turn()`

这说明恢复逻辑不是 fresh turn 的附属分支，而是一条正式路径。

在 resume 场景里，这层会重新回答：

- 哪些 tool run 已经有输出，不该再跑
- 哪些调用已经被批准，可以继续
- 哪些调用被拒绝，要生成 rejection item
- 哪些调用仍然需要继续挂起成 interruption

## 被拒绝的调用为什么会变成显式输出

`run_internal/approvals.py` 和 `run_internal/items.py` 都体现了一个重要原则：

审批拒绝不会只停留在本地状态里，而是会生成明确的 tool output。

例如：

- `append_approval_error_output()`
- `function_rejection_item()`
- `shell_rejection_item()`
- `apply_patch_rejection_item()`

这意味着“拒绝执行”在这套 SDK 里不是静默吞掉，而是会被整理成模型下一轮可见的结果。

这样模型后续才能基于“这个调用被拒绝了”继续规划。

## 一个具体场景怎么理解这条恢复链

如果某一轮里模型同时规划了几个工具，其中一个需要人工审批，那么系统不会把整轮全部作废，而是会：

- 先保留已经完成的部分
- 把待审批的调用封装成 interruption
- 等用户显式 approve / reject
- 再只继续推进剩余调用

这个场景能帮助我记住：approval 恢复语义的核心是“带防重的局部续跑”，不是“整轮重放”。

## 最该记住的点

- approval 在源码里首先是运行时状态，不是 UI 行为
- `ToolApprovalItem` 是控制流暂停点，不是普通历史 item
- `to_state()` 把 interruption 编码进 `RunState`
- resume 会跳过已有 output 的调用，只推进还没完成、且状态已明确的部分
- reject 结果会变成显式 output，而不是静默丢弃

## 易错点

- 容易把 approval 理解成 UI 层行为
- 容易以为 interruption 后就是整轮重跑
- 容易忽略 approval key 的复杂性，只按工具名思考 approve / reject
- 容易把 `ToolApprovalItem` 当普通历史 item，看漏它其实不能 replay 给模型

## 我的理解

OpenAI Agents SDK 把 approval 做成了一种“可序列化、可恢复、可局部继续执行”的控制流机制。

所以它的重点不在“怎么询问用户”，而在“暂停之后怎样不丢状态、怎样不重复执行、怎样让拒绝结果也能进入后续推理”。

## 相关笔记

- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK RunItem 与 stream event 数据结构]]
- [[OpenAI Agents SDK handoff 交接语义与输入迁移]]
