---
tags:
  - 主题
  - OpenAI Agents SDK
  - tool_execution
  - 源码
type: note
---

# OpenAI Agents SDK tool_execution 工具执行流

## 这页的定位

`turn_resolution.py` 决定“这一轮要不要跑工具”。

而 `tool_execution.py` 负责回答另一个更具体的问题：

“决定跑之后，这些工具到底怎么被归一化、审批、执行、报错、追踪并收束回 runtime。”

## 1. 这个文件不是单纯的工具调用器

从文件结构看，`tool_execution.py` 同时承接了四类职责：

- 工具调用 payload 归一化
- approval / interruption 相关处理
- 各类工具的真实执行
- tool guardrail / tracing / error formatting 收口

所以它更像“工具执行运行时”，而不是一个简单 helper 文件。

## 2. 先做归一化，再做执行

这个文件前半段有很多看起来很碎的函数，比如：

- `extract_tool_call_id`
- `coerce_shell_call`
- `parse_apply_patch_custom_input`
- `parse_apply_patch_function_args`
- `extract_apply_patch_call_id`
- `coerce_apply_patch_operations`
- `normalize_shell_output`
- `serialize_shell_output`

这些函数的共同作用是：

把不同来源、不同形态的 tool payload，先变成 runtime 内部更稳定的数据结构。

所以阅读时不要把它们当成杂项；它们其实是在给后面的统一执行打地基。

## 3. approval 是主线能力，不是外挂

这个文件里有一整块函数都和审批相关：

- `resolve_approval_status`
- `resolve_approval_interruption`
- `resolve_approval_rejection_message`
- `function_needs_approval`
- `process_hosted_mcp_approvals`
- `collect_manual_mcp_approvals`
- `index_approval_items_by_call_id`

这说明 SDK 把工具审批看成运行主线的一部分。

也就是说，工具执行并不是：

“看到 tool call 就直接跑。”

而更像：

1. 先判断是否需要 approval
2. 如果需要，生成 interruption 或 approval item
3. 批准后再执行
4. 拒绝时生成 rejection output 或错误消息

这和普通 demo 型 agent 最大的差别之一，就是它把人工审批正式纳入了 runtime。

## 4. function tool 的执行明显最复杂

从源码结构看，最重的部分是 function tool 批量执行。

相关关键对象和函数包括：

- `_FunctionToolFailure`
- `_FunctionToolTaskState`
- `_FunctionToolBatchExecutor`
- `execute_function_tool_calls`

我当前的理解是：

- 这里不是串行一个个跑 function tool
- 而是支持并发批处理
- 同时又要在并发过程中处理取消、失败优先级、后台任务清理和后置阶段异常

所以这个文件很大，不是因为功能乱，而是因为它认真处理了并发工具执行中的很多边缘情况。

## 5. 为什么 `_FunctionToolBatchExecutor` 值得记住

如果以后只想抓 `tool_execution.py` 的一个核心对象，我会优先记这个类。

原因是它集中体现了这套 SDK 对 function tool 执行的态度：

- 不是 naive parallelism
- 而是带故障仲裁、取消传播、后置等待和结果收集的批量执行器

从这个类能看出作者比较在意：

- 哪个错误应该成为主错误
- 取消后后台任务怎么排干
- post-invoke 阶段的失败会不会掩盖根因

这类细节很像真正跑过复杂 agent 工具链后才会补上的工程处理。

## 6. 公开执行函数是“按工具族分发”的

真正对外给 `run_internal` 其它模块调用的执行入口主要是这些：

- `execute_function_tool_calls`
- `execute_custom_tool_calls`
- `execute_local_shell_calls`
- `execute_shell_calls`
- `execute_apply_patch_calls`
- `execute_computer_actions`
- `execute_approved_tools`

这说明这一层不是按“单个工具”处理，而是按“工具类型家族”分发。

所以更适合的理解方式是：

- `turn_resolution` 决定“这一轮有哪些工具任务”
- `tool_execution` 决定“每一类工具任务怎么执行”

## 7. tool guardrails 其实也在这里收口

这个文件后段还有：

- `_execute_tool_input_guardrails`
- `_execute_tool_output_guardrails`

这点很重要，因为它说明 tool guardrail 并不是一个完全独立的子系统。

更准确地说：

- guardrail 的定义在别处
- 真正贴着工具执行时机调用 guardrail 的地方在 `tool_execution.py`

所以这层是工具运行时真正发生约束的地方。

## 8. tracing 也不是最后再补的

`with_tool_function_span` 这类函数说明：

- 工具执行从一开始就被包在 tracing span 里
- 错误消息是否暴露敏感信息也会在这里处理

这说明 tracing 和 error formatting 都不是“执行完再记一笔日志”，而是工具执行路径的原生组成部分。

## 9. 一条我现在更认可的执行心智模型

当某轮决定执行工具时，`tool_execution.py` 更像是在跑下面这条链：

1. 识别工具调用 ID 和 payload
2. 归一化成统一内部格式
3. 判断是否需要 approval
4. 必要时产生 interruption / rejection
5. 进入具体工具族执行函数
6. 在执行前后跑 tool guardrails
7. 把结果、错误和 tracing 一并收束
8. 返回给 `turn_resolution` 继续决定下一步

## 10. 这一层和 `turn_resolution.py` 的边界

我目前会这样区分两者：

### `turn_resolution.py`

负责决定：

- 跑不跑工具
- 跑哪类工具
- 跑完之后下一步是继续、handoff、结束还是中断

### `tool_execution.py`

负责决定：

- 这些工具具体怎么跑
- 审批怎么插入
- 错误怎么裁决
- 输出怎么规范化

所以：

- `turn_resolution` 偏策略分流
- `tool_execution` 偏执行基础设施

## 11. 我会怎么记这页

### payload helpers

把原始 tool payload 变成内部可执行格式

### approval helpers

决定工具能不能执行、是否需要中断

### batch executor

处理 function tool 的并发执行、失败仲裁与清理

### family executors

分别执行 function / shell / local shell / apply_patch / computer

### guardrail + tracing

在工具执行时机真正落地约束和观测

## 12. 下一步最值得补的细化方向

- `_FunctionToolBatchExecutor` 的失败仲裁细节
- `execute_approved_tools` 的恢复语义
- shell / apply_patch / computer 三类工具的差异
