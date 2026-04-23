---
tags:
  - 主题
  - OpenAI Agents SDK
  - run_internal
  - 源码
type: note
---

# OpenAI Agents SDK run_internal 执行链路

## 这页的用途

这页不是再讲一遍 Agent 概念，而是专门回答一个更实用的问题：

`Runner.run()` 进入 `run_internal/` 之后，代码到底怎么分层、数据怎么在各层之间流动。

## 1. `run_internal/` 里的几个关键角色

### `run_steps.py`

这是中间数据结构层。

它定义了运行循环里最常见的“执行单元”和“下一步决策”：

- `ProcessedResponse`
- `SingleStepResult`
- `NextStepFinalOutput`
- `NextStepHandoff`
- `NextStepRunAgain`
- `NextStepInterruption`

我会把它看成整条执行链的“状态交换协议”。

尤其 `ProcessedResponse` 很关键，因为它把一次模型响应拆成了：

- 新产出的 items
- handoff 列表
- function tool 列表
- computer action
- shell call
- apply_patch call
- MCP approval request
- interruption

也就是说，模型先给出原始 response，`run_internal` 再把它规整成一个可执行计划。

### `turn_preparation.py`

这是“本轮准备层”。

它主要负责：

- 校验 `RunHooks`
- 解析 output schema
- 拿到当前 agent 可用的 handoffs
- 拿到当前 agent 可用的 tools
- 解析当前要用的 model
- 在必要时过滤模型输入

所以它回答的是：

“这一次 turn 开始前，我们到底准备了什么运行材料。”

### `turn_resolution.py`

这是“本轮解析与决策层”。

它负责把模型输出变成下一步动作。

这里最值得记住的事情是：

- 它不仅解析 final output
- 还会识别 handoff、tool call、interruptions
- 并根据工具结果决定是否能直接收束成 final output

我会把这层理解成：

“把模型的表达，翻译成 runtime 能执行的下一步。”

### `tool_execution.py`

这是“工具执行层”。

它不只做 function tool 调用，还负责：

- approval plumbing
- shell call / local shell
- apply patch
- computer action
- hosted MCP approval 相关处理
- tool error / tracing / guardrail 配套逻辑

所以不要把它理解成一个简单的 `invoke(tool)` 文件，它其实是工具运行期的基础设施层。

### `session_persistence.py`

这是“持久化层”。

它主要负责：

- 把 session history 和新输入合成可发给模型的输入
- 在 guardrail 触发时保存必要输入
- 把本轮新增的 run items 落进 session
- interruption / resume 后修正 `RunState`

这层说明 SDK 对“多轮状态”不是事后拼接，而是运行时主线的一部分。

### `run_loop.py`

这是“总编排层”。

它把前面这些模块真正串在一起，并提供几个关键入口：

- `start_streaming`
- `run_single_turn_streamed`
- `run_single_turn`
- `get_new_response`

可以理解为：

- 其他文件在分工
- `run_loop.py` 在真正推动这一轮往前走

## 2. 一次 turn 的粗粒度流向

我当前整理出来的执行顺序是：

1. `turn_preparation.py` 先准备 model、tools、handoffs、output schema
2. `run_loop.py` 请求模型，拿到新的 response
3. `turn_resolution.py` 处理 response，生成 `ProcessedResponse`
4. 如果是 final output，就走 finalization
5. 如果是 handoff，就切 agent
6. 如果有 tools / approvals，就交给 `tool_execution.py`
7. 本轮新增 items 与结果再交给 `session_persistence.py`
8. `run_loop.py` 根据 `NextStep*` 决定下一轮还是结束

## 3. 为什么 `run_steps.py` 特别重要

很多时候读源码会迷路，不是因为函数太复杂，而是因为不知道“数据此刻长什么样”。

这时 `run_steps.py` 特别关键，因为它告诉你：

- 一次响应被拆成哪些执行项
- 一次 step 最终会产出什么
- runtime 允许哪些下一步状态

如果先不看这个文件，直接冲进 `run_loop.py`，很容易只看到大量 if/else 和 helper 调用。

## 4. 我对几个关键对象的记忆方式

### `ProcessedResponse`

“模型响应的可执行计划”

### `SingleStepResult`

“这一轮执行完后的汇总结果”

### `NextStepFinalOutput`

“可以结束”

### `NextStepHandoff`

“切给另一个 agent”

### `NextStepRunAgain`

“还要继续下一轮”

### `NextStepInterruption`

“先停下来，等审批或恢复”

## 5. `run_loop.py` 的阅读建议

这个文件函数很多，而且同时覆盖 streamed / non-streamed 两条路径。

更适合的阅读方式不是从头顺读，而是按这条顺序抓主函数：

1. `run_single_turn`
2. `get_new_response`
3. `run_single_turn_streamed`
4. `start_streaming`

然后再回头看：

- streamed final output 怎么收尾
- interruption 怎么补存 session
- output guardrails 在流式路径里怎么处理

## 6. 现在最适合继续补的细化方向

- `turn_resolution.py` 的“从 response 到 `ProcessedResponse`”细拆
- `tool_execution.py` 里的 approval 与 error handling 机制
- `session_persistence.py` 的 dedupe / normalize / resume 细节
- streamed 与 non-streamed 两条路径的差异
