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

## 我研究这部分时最关心什么

- `run_internal/` 为什么要拆成这么多文件
- 每个文件解决的是准备、解析、执行还是持久化问题
- `run_steps.py` 里的中间对象为什么是理解整条链的关键

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

### `turn_preparation.py`

这是“本轮准备层”。

它主要负责：

- 校验 `RunHooks`
- 解析 output schema
- 拿到当前 agent 可用的 handoffs
- 拿到当前 agent 可用的 tools
- 解析当前要用的 model
- 在必要时过滤模型输入

### `turn_resolution.py`

这是“本轮解析与决策层”。

它负责把模型输出变成下一步动作。

### `tool_execution.py`

这是“工具执行层”。

它不只做 function tool 调用，还负责：

- approval plumbing
- shell call / local shell
- apply patch
- computer action
- tool error / tracing / guardrail 配套逻辑

### `session_persistence.py`

这是“持久化层”。

它主要负责：

- 把 session history 和新输入合成可发给模型的输入
- 在 guardrail 触发时保存必要输入
- 把本轮新增的 run items 落进 session
- interruption / resume 后修正 `RunState`

### `run_loop.py`

这是“总编排层”。

它把前面这些模块真正串在一起，并提供几个关键入口：

- `start_streaming`
- `run_single_turn_streamed`
- `run_single_turn`
- `get_new_response`

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

## 5. 我的理解

`run_internal/` 最值得学的地方，不只是它把逻辑拆开了，而是它把 agent 执行过程明确建成了一套可传递、可恢复、可分流的运行协议。

## 相关笔记

- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
