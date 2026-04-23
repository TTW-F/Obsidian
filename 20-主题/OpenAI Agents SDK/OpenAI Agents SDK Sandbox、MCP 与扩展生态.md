---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - MCP
  - 扩展
type: note
---

# OpenAI Agents SDK Sandbox、MCP 与扩展生态

## 1. Sandbox 是近阶段最值得深挖的一层

从 README、`docs/zh/sandbox_agents.md` 和 `src/agents/sandbox/` 的体量来看，Sandbox 不是附属能力，而是新一代重点方向。

它的意义不是“多一个工具”，而是让 agent 进入一个真实、隔离、可恢复的工作区去做事。

核心入口包括：

- `sandbox_agent.py`
- `manifest.py`
- `runtime.py`
- `snapshot.py`
- `capabilities/`
- `session/`
- `memory/`
- `sandboxes/unix_local.py`
- `sandboxes/docker.py`

## 2. MCP 是外部工具生态接入点

`src/agents/mcp/` 说明这套 SDK 没把工具能力完全限制在本地函数层。

重点入口：

- `manager.py`
- `server.py`
- `util.py`

这让 agent 可以从 MCP server 动态获得工具，而不是所有东西都内嵌在应用代码里。

## 3. 模型层本身支持扩展

从 `src/agents/models/` 和 `src/agents/extensions/models/` 看，模型层是显式抽象出来的：

- `Model`
- `ModelProvider`
- OpenAI Responses / Chat Completions
- `MultiProvider`
- LiteLLM / any-llm 扩展

这也是为什么 README 会强调 provider-agnostic。

## 4. Realtime 与 Voice 是另一条能力线

仓库里还有两块大子系统：

- `src/agents/realtime/`
- `src/agents/voice/`

我的理解是：

- Realtime 更偏低延迟实时会话基础设施
- Voice 更偏完整语音工作流

它们都不是最小主线的一部分，但代表这套 SDK 向多模态和实时交互扩展的方向。

## 5. 还有一块值得后续单开笔记

`src/agents/extensions/experimental/codex/`

这一块已经不是基础使用文档能覆盖的内容了，更像实验性能力扩展，很适合后面单独再拆。

## 6. 推荐先看的示例

- `examples/sandbox/README.md`
- `examples/sandbox/basic.py`
- `examples/sandbox/sandbox_agent_with_tools.py`
- `examples/sandbox/memory.py`
- `examples/mcp/`
- `examples/model_providers/`
- `examples/realtime/`
