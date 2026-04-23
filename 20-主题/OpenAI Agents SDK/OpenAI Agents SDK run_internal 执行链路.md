---
tags:
  - 主题
  - OpenAI Agents SDK
  - run_internal
  - 源码
type: note
---

# OpenAI Agents SDK run_internal 执行链路

## 这是什么

这篇笔记专门用来回答一个源码层问题：`Runner.run()` 进入 `run_internal/` 之后，执行链到底分成哪些层，数据又是怎样在这些层之间流动的。

重点是把目录里的职责分工和数据流讲清楚。

## 为什么重要

- `run_internal/` 是理解这套 SDK 运行时骨架的核心目录
- 如果只看单个函数，很容易迷路；先看分层，再看细节，理解会稳得多
- 这里的中间对象也决定了后面工具执行、handoff 和状态持久化怎样接起来

## 核心概念

### `run_internal/` 里最关键的几个角色

### `run_steps.py`：状态交换协议

`run_steps.py` 可以先看成执行链里的“状态交换协议”。

这里定义的对象，例如：

- `ProcessedResponse`
- `SingleStepResult`
- `NextStepFinalOutput`
- `NextStepHandoff`
- `NextStepRunAgain`
- `NextStepInterruption`

共同回答的是：一轮模型响应被整理后，运行时允许进入哪些下一步状态。

如果只记一个最关键文件，可以先记它，因为它告诉我“当前数据长什么样”。

### `turn_preparation.py`：本轮准备层

这层主要负责在真正请求模型前把上下文准备好，包括：

- 校验 `RunHooks`
- 解析 output schema
- 收集当前 agent 可用的 handoffs
- 收集当前 agent 可用的 tools
- 解析本轮要用的 model
- 在必要时过滤模型输入

它对应的问题不是“如何执行”，而是“这轮执行的材料有没有备齐”。

### `turn_resolution.py`：本轮决策层

这层负责把模型输出翻译成运行时下一步动作。

比如模型返回后，到底是直接结束、切换 handoff、继续跑工具，还是进入 interruption，决策主要都在这里完成。

### `tool_execution.py`：工具执行层

这一层真正处理工具怎么跑。它不只负责 function tool 调用，也覆盖 approval、shell、apply patch、computer action，以及执行过程里的 tracing 和 guardrail 配套逻辑。

### `session_persistence.py`：状态延续层

这一层负责把 session history 和新输入组合成模型输入，并在 turn 结束后把新增的 run items 安全写回 session。

它的重点不只是保存，更包括防重、回滚、resume 和 interruption 后的状态修正。

### `run_loop.py`：总编排层

这层把前面几部分真正串起来，也是我理解“一次 turn 怎样跑完”的最好入口。

## 一次 turn 的粗粒度流向

一轮执行可以先按下面顺序理解：

1. `turn_preparation.py` 准备 model、tools、handoffs 和 output schema
2. `run_loop.py` 请求模型，拿到新的 response
3. `turn_resolution.py` 把 response 解析成 `ProcessedResponse`
4. 如果结果是 final output，就走结束分支
5. 如果结果是 handoff，就切换 agent
6. 如果结果包含工具动作或 approval，就交给 `tool_execution.py`
7. 本轮新增 items 与结果再交给 `session_persistence.py`
8. `run_loop.py` 根据 `NextStep*` 决定结束、继续下一轮，还是进入 interruption

## 一个最值得抓住的观察

`run_internal/` 的价值不只在“拆文件”，而在它把 agent 执行过程建成了一套可分流、可恢复、可继续推进的运行协议。

`run_steps.py` 之所以关键，就是因为这些中间对象让整个协议可见了。

## 常见操作 / 用法

- 先看 `run_steps.py`，确认有哪些标准状态
- 再看 `run_loop.py`，确认这些状态怎样被串起来
- 最后再分别钻进 `turn_resolution.py`、`tool_execution.py` 和 `session_persistence.py`

如果顺序反过来，很容易一开始就陷在局部 helper 里。

## 易错点

- 容易把 `run_internal/` 看成实现细节，但它其实就是运行时骨架
- 容易直接从 `tool_execution.py` 开始，结果忽略前面的准备和决策层
- 容易记函数名，不记中间对象，最后还是看不清数据流

## 我的理解

`run_internal/` 最值得学的地方，不只是“模块分得很细”，而是它把 agent 执行拆成了一组明确的阶段和状态。

只要把这些阶段和状态先抓稳，后面很多源码细节就不再是零散函数，而会变成同一条运行链上的不同节点。

## 相关笔记

- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK 运行时编排]]
