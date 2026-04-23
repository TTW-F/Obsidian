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

## 这篇笔记要解决什么

这篇不盯某一个源码文件，而是回答一个更整体的问题：

这套 SDK 到底把哪些运行时能力编织在了一起，才让一次 run 变成真正的 agent 执行过程。

## 我研究这部分时最关心什么

- tools、handoffs、guardrails、sessions、tracing 分别解决什么问题
- 它们是并列模块，还是被织进同一条执行链
- 这套 runtime 的“治理层”体现在哪里

## 1. Tool 解决“去做事”

`src/agents/tool.py` 是工具系统主入口。

这里不只是一层 `@function_tool`，而是收拢了多类能力：

- FunctionTool
- Hosted tools
- MCP tool
- Shell / Computer / ApplyPatch
- Agent as tool

所以 tool 在这套 SDK 里不是边角功能，而是主运行链路的一部分。

## 2. Handoff 解决“换谁继续做”

`src/agents/handoffs/` 负责 agent 间委派。

它和 tool 的关键差异是：

- tool 调完后，主 agent 通常继续掌控流程
- handoff 发生后，新 agent 接管后续对话与处理

所以 handoff 更像角色切换，而不是子任务调用。

## 3. Guardrail 解决“先检查再推进”

相关入口：

- `src/agents/guardrail.py`
- `src/agents/tool_guardrails.py`
- `src/agents/run_internal/guardrails.py`

这里既有 agent 级 guardrail，也有 tool 级 guardrail。

我更愿意把它理解成运行时治理层，而不是简单校验函数。

## 4. Session 解决“多轮怎么接上”

`src/agents/memory/` 是 session 与会话状态的核心目录。

重点文件：

- `session.py`
- `sqlite_session.py`
- `openai_conversations_session.py`
- `openai_responses_compaction_session.py`

从这里能看出来，SDK 对“历史记录怎么存”没有写死成一种方式，而是提供了协议和多种实现。

## 5. Tracing 解决“过程怎么看得见”

`src/agents/tracing/` 把运行拆成 trace / span 体系。

对理解这套 SDK 来说，Tracing 很重要，因为它直接揭示了作者心中的“关键运行单元”：

- task
- turn
- agent
- generation
- function
- handoff
- guardrail

也就是说，Tracing 不是附属品，而是对内部运行模型的另一种显性表达。

## 6. 这几个模块怎样串起来

我目前的串联方式是：

1. `Runner` 发起一轮
2. 先过 guardrail
3. 模型返回结果
4. 结果可能变成 final output、handoff 或 tool call
5. 工具执行过程可能继续被 guardrail 和 tracing 包裹
6. 每轮的输入输出被 session 持久化
7. 整个过程都落进 trace / span

## 7. 建议一起读的文档和示例

- `docs/zh/running_agents.md`
- `docs/zh/tools.md`
- `docs/zh/handoffs.md`
- `docs/zh/guardrails.md`
- `docs/zh/tracing.md`
- `examples/basic/tools.py`
- `examples/agent_patterns/agents_as_tools.py`
- `examples/agent_patterns/routing.py`
- `examples/agent_patterns/input_guardrails.py`
- `examples/memory/`

## 我的理解

这套 SDK 最值得学的不是某个单点功能，而是它把执行、委派、治理、持久化和观测织进了同一条运行时主线。

## 相关笔记

- [[OpenAI Agents SDK 研究路线]]
