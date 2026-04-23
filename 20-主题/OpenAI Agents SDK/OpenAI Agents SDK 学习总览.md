---
tags:
  - 主题
  - OpenAI Agents SDK
  - AI Agent
type: topic
---

# OpenAI Agents SDK 学习总览

## 这套仓库最值得先建立的心智模型

OpenAI Agents SDK 不是“调用一次模型然后返回”的轻封装，而是一套会持续推进多轮流程的运行时。

如果只记一条主线，可以记成：

1. 用 `Agent` 定义角色、工具、handoffs、guardrails 和输出模式
2. 用 `Runner` 启动一次 run
3. `run_internal/` 负责把一轮轮执行拆开
4. 在执行中穿插 tool、handoff、guardrail、session persistence 和 tracing
5. 更复杂场景再接上 sandbox、mcp、realtime、voice

## 建议阅读顺序

- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK 示例与学习路径]]

## 最关键的文档入口

仓库里已经给了中文文档，优先级最高的是：

- `docs/zh/index.md`
- `docs/zh/quickstart.md`
- `docs/zh/running_agents.md`
- `docs/zh/tools.md`
- `docs/zh/sandbox_agents.md`
- `docs/zh/tracing.md`
- `docs/zh/sessions/index.md`

## 最关键的源码入口

- `src/agents/__init__.py`
- `src/agents/agent.py`
- `src/agents/run.py`
- `src/agents/run_internal/`
- `src/agents/tool.py`
- `src/agents/memory/`
- `src/agents/tracing/`
- `src/agents/sandbox/`

## 我当前对它的一句话理解

这套 SDK 的核心价值，是把模型调用升级成“可编排、可委派、可观测、可带状态、可进入真实工作区”的 agent 运行过程。
