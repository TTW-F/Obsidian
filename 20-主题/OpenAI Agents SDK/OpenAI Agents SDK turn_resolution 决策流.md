---
tags:
  - 主题
  - OpenAI Agents SDK
  - turn_resolution
  - 源码
type: note
---

# OpenAI Agents SDK turn_resolution 决策流

## 这页的定位

如果说 `run_internal` 是执行引擎，那么 `turn_resolution.py` 就是“决策中枢”。

它最核心的职责不是调用模型，也不是执行工具，而是把模型已经给出的结果翻译成 runtime 真正要做的下一步。

## 1. 这个文件最关键的公开函数

从文件入口看，最重要的是这些函数：

- `process_model_response`
- `get_single_step_result_from_response`
- `execute_handoffs`
- `execute_tools_and_side_effects`
- `check_for_final_output_from_tools`
- `execute_final_output`
- `resolve_interrupted_turn`

可以粗略把它们分成三类：

- 解析模型响应
- 决定下一步分支
- 把本轮收束成 `SingleStepResult`

## 2. 它真正解决的问题

模型返回 response 之后，runtime 其实还不知道应该做什么。

需要再判断：

- 这是最终答案吗
- 这是 handoff 吗
- 这是 function tool / shell / computer / apply_patch 调用吗
- 这里面有审批中断吗
- 工具结果能不能直接转成 final output

`turn_resolution.py` 负责把这些问题变成明确的 runtime 结果。

## 3. `process_model_response` 的角色

这应该是这个文件最重要的解析入口。

它的意义可以概括成一句话：

“把模型原始 response 拆成 `ProcessedResponse`。”

而 `ProcessedResponse` 里已经不是原始 response item，而是被分门别类后的可执行计划：

- `handoffs`
- `functions`
- `computer_actions`
- `local_shell_calls`
- `shell_calls`
- `apply_patch_calls`
- `mcp_approval_requests`
- `interruptions`
- `new_items`

所以从阅读角度讲：

- `run_steps.py` 定义了容器
- `process_model_response` 负责把内容装进这个容器

## 4. `get_single_step_result_from_response` 的角色

这个函数更像“本轮总装器”。

我的理解是，它会基于：

- 原始输入
- 新的模型 response
- `ProcessedResponse`
- 当前 agent / hooks / context

决定当前这一轮最终应该产出什么类型的 `SingleStepResult`。

也就是说，它负责把前面的解析结果真正落成：

- `NextStepFinalOutput`
- `NextStepHandoff`
- `NextStepRunAgain`
- `NextStepInterruption`

## 5. `execute_handoffs` 做了什么

这个函数不只是“切换 agent”这么简单。

从源码能看到它还处理了：

- 多个 handoff 同时出现时的冲突处理
- handoff output item 的补写
- hooks 的 handoff 回调
- input filter
- `nest_handoff_history`
- server-managed conversation 的兼容限制

所以 handoff 在这里不是一个简单布尔分支，而是一整套“交接上下文”的迁移逻辑。

这也是为什么 handoff 很容易被低估。

## 6. `execute_tools_and_side_effects` 的角色

这个函数的名字已经很说明问题了。

它不只是在“跑工具”，而是在处理一切需要进一步执行的副作用，包括：

- function tool
- shell / local shell
- apply patch
- computer action
- hosted MCP approval 相关动作

更重要的是，它不是单独闭环，它会把工具执行结果再交回当前 step 的推进逻辑里。

也就是说：

- 工具执行不等于 turn 结束
- 工具执行只是 turn resolution 的一个分支阶段

## 7. `check_for_final_output_from_tools`

这是一个很值得记住的点。

很多人会默认以为 final output 只能来自模型直接回答，但这个函数说明：

- 工具结果也可能被提升成 final output
- 这取决于 agent 的 `tools_to_final_output` 语义

所以 runtime 的“结束条件”不只是模型消息，也可能是工具返回值。

这点对理解 agent as tool 和工具主导型工作流很重要。

## 8. `execute_final_output`

一旦确定这轮可以结束，就会走 final output 路径。

这一步主要做的是：

- 调用 `run_final_output_hooks`
- 构造 `SingleStepResult`
- 把 `next_step` 标成 `NextStepFinalOutput`

所以它的核心价值不是复杂处理，而是把“已经确定结束”这件事包装成 runtime 标准结果。

## 9. `resolve_interrupted_turn`

这个函数的存在说明，审批与中断不是附属分支，而是主线分支之一。

它要处理的问题是：

- 某轮被 approval 打断后，恢复时怎么继续
- 哪些 tool call 重新执行
- 哪些 items 保留
- 哪些结果需要补回当前 step

所以 interruption / resume 不是简单“从头再来”，而是要接着上一轮的局部状态往下走。

## 10. 我会怎么记这整页

### `process_model_response`

把 response 解析成可执行计划

### `get_single_step_result_from_response`

把可执行计划收束成一步结果

### `execute_handoffs`

处理交接与上下文迁移

### `execute_tools_and_side_effects`

处理工具与副作用分支

### `execute_final_output`

处理结束分支

### `resolve_interrupted_turn`

处理中断恢复分支

## 11. 这一层和上一页怎么配合看

可以这样串：

- [[OpenAI Agents SDK run_internal 执行链路]] 负责看总分层
- 这一页负责看 `turn_resolution.py` 里的决策分流

也就是：

- 上一页回答“有哪些层”
- 这一页回答“决定往哪条路走的是谁”

## 12. 下一步最适合继续补什么

- `process_model_response` 具体如何按 item 类型分类
- `execute_tools_and_side_effects` 和 `tool_execution.py` 的边界
- `resolve_interrupted_turn` 的恢复语义

## 相关笔记

- [[OpenAI Agents SDK tool_execution 工具执行流]]
