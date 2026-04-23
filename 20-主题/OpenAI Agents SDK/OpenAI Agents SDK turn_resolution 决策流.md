---
tags:
  - 主题
  - OpenAI Agents SDK
  - turn_resolution
  - 源码
type: note
---

# OpenAI Agents SDK turn_resolution 决策流

## 这是什么

这篇笔记记录 `turn_resolution.py` 在运行时里的位置：模型已经返回结果之后，系统怎样把这些结果翻译成“下一步真正要执行什么”。

它更适合作为决策层笔记来读，而不是工具执行层笔记。

## 为什么重要

- 一次模型响应不会天然等于一次可执行动作，运行时需要先做解释和分流
- 这层决定后面是结束、handoff、跑工具、进入 interruption，还是继续下一轮
- 不理解这里，就很难区分“模型说了什么”和“运行时决定怎么做”之间的差别

## 核心概念

`turn_resolution.py` 可以先记成“本轮决策层”。

它不直接请求模型，也不直接执行工具，而是把模型输出整理成下一步动作，例如：

- 结束
- handoff
- 执行工具
- 中断等待审批
- 继续下一轮

## 最关键的几个函数

### `process_model_response`

这是最推荐先看的函数。

它负责把模型原始 response 解析成 `ProcessedResponse`。可以先把 `ProcessedResponse` 理解成：

“这一轮模型结果被整理后的可执行计划”。

这里通常会区分出：

- handoffs
- functions
- shell calls
- local shell calls
- apply patch calls
- computer actions
- approval requests
- interruptions
- new items

### `get_single_step_result_from_response`

这个函数负责把前面的解析结果收束成 `SingleStepResult`。

换句话说，它在决定：这一步最后到底落成哪种 `NextStep*`。

### `execute_handoffs`

这里处理的不是简单的“切一下 agent”，而是一整次交接：

- handoff 冲突处理
- handoff 产物补写
- hooks 回调
- 输入过滤
- 上下文迁移

所以 handoff 更像运行时里的角色交接，而不是普通分支跳转。

### `execute_tools_and_side_effects`

这个函数是本轮需要继续执行动作的统一入口。

它不只处理 function tool，还会处理：

- shell
- local shell
- apply patch
- computer action
- approval 相关副作用

### `check_for_final_output_from_tools`

这是一个很值得先记住的点。

final output 不一定只来自模型直接回答，也可能来自工具结果。这对理解工具主导型工作流很重要。

### `resolve_interrupted_turn`

这个函数说明 interruption 不是“从头重来”，而是“从被打断的位置继续往下接”。

恢复时要重新处理：

- 哪些 tool call 还能继续
- 哪些 items 要保留
- 哪些状态要回填

## 这一层的数据流

可以先记成三步：

1. 先解析模型输出
2. 再决定下一步分支
3. 最后把这一轮收束成标准结果

更具体一点就是：

- `process_model_response` 负责拆解
- `execute_handoffs` / `execute_tools_and_side_effects` 负责推进
- `get_single_step_result_from_response` 负责收束

## 一个具体场景

如果模型输出里同时包含一个 handoff 和一个 tool call，这层就必须先判定冲突关系，再决定哪个动作可以继续推进、哪个动作需要中止或改写。

这说明 `turn_resolution.py` 的重点不是“执行”，而是“解释和分流”。

## 常见操作 / 用法

- 想先抓总入口，先看 `process_model_response`
- 想看 handoff 怎么真正落地，接着看 `execute_handoffs`
- 想看工具与 approval 副作用怎么接进决策层，再看 `execute_tools_and_side_effects`
- 想看中断恢复怎么衔接，继续看 `resolve_interrupted_turn`

## 易错点

- 容易把 `turn_resolution.py` 误看成工具执行层，实际上它更像决策与分流层
- 容易只盯函数名，不去看 `ProcessedResponse` 和 `SingleStepResult` 这些中间对象
- 容易忽略 interruption / approval 分支，结果把执行链理解得过于线性

## 我的理解

`turn_resolution.py` 的核心价值，是把模型输出翻译成运行时真正能执行的下一步。

如果没有这层，模型的 response 只是结果文本；有了这层之后，它才会变成 final output、handoff、tool execution 或 interruption 这些真正有运行语义的动作。

## 相关笔记

- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK 运行时编排]]
