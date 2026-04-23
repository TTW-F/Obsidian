---
tags:
  - 主题
  - OpenAI Agents SDK
  - Tools
  - Handoffs
  - Guardrails
  - Session
  - Tracing
type: note
---

# OpenAI Agents SDK 运行时编排

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 在一次 run 里真正参与编排的几层能力，以及这些能力怎样一起决定 agent 的执行形态。

如果只看 `Agent` 和 `Runner`，很容易以为这套 SDK 只是模型调用外面再包一层；把 `tool`、`handoff`、`guardrail`、`session` 和 `tracing` 放回同一条运行主线里看，才更容易看出它为什么像一套 runtime。

## 为什么重要

- 如果只看 `Agent` 和 `Runner`，很容易把这套 SDK 误解成一次模型调用的封装
- 真正让它变成 agent 运行时的，是这些横切能力被直接编进了执行主线
- 理解这层关系后，再读 `run_internal/`、examples 和 docs 会更容易抓住主线

## 核心概念

### 一次 run 里最值得先记住的五层能力

### 1. Tool：让 agent 真正去做事

源码入口在 `src/agents/tool.py`。

从这里可以看到 SDK 不只支持一个 `@function_tool` 装饰器，而是把多类工具统一放进同一层能力模型里，例如 function tool、hosted tool、MCP tool，以及 shell、computer、apply patch 这类更接近工作区执行的能力。

这说明 tool 不是附属模块，而是运行时主线的一部分。

### 2. Handoff：让任务可以换 agent 继续

相关目录是 `src/agents/handoffs/`。

它和 tool 的关键区别是：

- tool 调完后，当前 agent 通常还继续掌控流程
- handoff 发生后，后续对话和处理权会转给另一个 agent

如果把 tool 理解成“调用能力”，那 handoff 更像“切换处理者”。

### 3. Guardrail：在推进前后插入检查

相关入口包括：

- `src/agents/guardrail.py`
- `src/agents/tool_guardrails.py`
- `src/agents/run_internal/guardrails.py`

这里能看到 guardrail 不是简单的输入校验函数，而是运行时的治理点。它既能发生在 agent 级，也能发生在 tool 级。

### 4. Session：让多轮状态接得上

相关目录是 `src/agents/memory/`，常见文件包括：

- `session.py`
- `sqlite_session.py`
- `openai_conversations_session.py`
- `openai_responses_compaction_session.py`

从这些文件可以看出，SDK 把“历史怎么存、怎么压缩、怎么续接”当成了运行时问题，而不是简单的输入拼接问题。

### 5. Tracing：让过程变得可观察

相关目录是 `src/agents/tracing/`。

这里最值得记住的一点是 trace / span 的划分直接暴露了作者眼里的关键运行单元，例如 task、turn、agent、generation、function、handoff、guardrail。

这意味着 tracing 不是最后补上的日志层，而是在把运行时结构显性化。

## 常见执行链

一次 run 可以先记成下面这条链：

1. `Runner` 启动一次执行
2. 运行时准备好 agent、model、tools、handoffs 和输入
3. 模型返回结果后，系统判断这是 final output、handoff 还是 tool call
4. 如果要执行工具，执行过程继续经过 approval、guardrail 和 tracing
5. 每一轮新增的输入输出被 session 记录下来
6. 整个过程持续落进 trace / span，便于回看和调试

## 一个具体场景

如果 agent 收到“去沙箱里运行命令、读结果、必要时换另一个 agent 继续处理”的任务，那么：

- tool 层负责真正执行命令或调用外部能力
- handoff 层负责把任务切给别的 agent
- guardrail 层负责在执行前后做检查
- session 层负责把这轮结果带到下一轮
- tracing 层负责让每一步可被回看

这个场景说明，这五层不是并排存在的功能清单，而是一次 run 里会连续经过的运行时部件。

## 常见操作 / 用法

- 想看“这一轮下一步到底怎么定”，重点读 `run_internal/turn_resolution.py`
- 想看“工具真正怎么跑”，接着读 `run_internal/tool_execution.py`
- 想看“多轮状态怎么延续”，再读 `run_internal/session_persistence.py`
- 想把这些运行时能力放进更大的整体里理解，可以回看 `src/agents/tool.py`、`src/agents/handoffs/`、`src/agents/guardrail.py`、`src/agents/memory/`、`src/agents/tracing/`

## 易错点

- 容易把这些能力记成横向功能列表，忽略它们都在参与同一条执行主线
- 容易只看 tool，不看 session 和 tracing，结果低估多轮执行和可观测性的分量
- 容易把 handoff 误解成普通工具调用，但它实际会改变后续处理者

## 我的理解

OpenAI Agents SDK 真正像 agent 运行时的地方，不是支持了多少 API，而是把做事、换人、检查、续接和观测都放进了一次 run 的默认结构里。

如果只把这些模块当成功能外挂，就很难理解为什么这套 SDK 的复杂度会明显高于“请求模型再拿结果”。

## 相关笔记

- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
