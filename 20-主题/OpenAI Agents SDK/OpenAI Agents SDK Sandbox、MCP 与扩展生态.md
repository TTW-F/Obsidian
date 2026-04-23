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

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 在主执行链之外几条最重要的扩展方向：Sandbox、MCP、模型 provider、realtime 和 voice。

它要回答的问题不是“仓库里还有哪些目录”，而是这些扩展分别把 agent 的能力边界推进到了哪里。

## 为什么重要

- 如果只看基础运行链，很容易低估这套 SDK 向真实工作环境扩展的力度
- Sandbox、MCP 和 provider 决定 agent 能接入什么环境、什么工具、什么模型
- realtime 和 voice 则说明这套 runtime 不只服务于传统文本回合

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

如果把普通 agent 理解成“会调用工具的对话体”，那 `SandboxAgent` 更像“能在隔离工作区里持续做事的执行体”。

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

这也是为什么 README 会强调 provider-agnostic。对使用者来说，这层的意义不是“多一个模型接口”，而是把模型选择从具体 agent 逻辑里拆了出来。

## 4. Realtime 与 Voice 是另一条能力线

仓库里还有两块大子系统：

- `src/agents/realtime/`
- `src/agents/voice/`

它们各自更偏向：

- Realtime：低延迟实时会话基础设施
- Voice：完整语音工作流

它们都不是最小主线的一部分，但代表这套 SDK 向多模态和实时交互扩展的方向。

## 5. 还有一块值得后续单开笔记

`src/agents/extensions/experimental/codex/`

这一块已经不是基础使用文档能覆盖的内容了，更像实验性能力扩展，很适合后面单独再拆。

## 常见操作 / 用法

- 想理解“agent 为什么会变成工作区执行体”，优先看 `examples/sandbox/README.md`、`examples/sandbox/basic.py`、`examples/sandbox/sandbox_agent_with_tools.py`
- 想理解 sandbox 的长期状态能力，再看 `examples/sandbox/memory.py`
- 想理解外部工具生态怎么接进来，进入 `examples/mcp/`
- 想理解模型抽象层，进入 `examples/model_providers/`
- 想理解实时与语音方向，再看 `examples/realtime/`

## 易错点

- 容易把 Sandbox 看成“多一个工具”，而忽略它其实改变了 agent 的运行环境
- 容易把 MCP 理解成普通工具封装，但它更像外部工具生态的接入层
- 容易把 provider 扩展只看成兼容层，忽略模型抽象本身也是 runtime 设计的一部分
- 容易因为 realtime 和 voice 不在最短学习路径里，就低估它们对整体架构边界的提示价值

## 我的理解

OpenAI Agents SDK 的扩展线不是在主链外面随便挂几个模块，而是在不断把“agent 能工作的环境”往更真实的系统边界推进。

其中最值得先抓住的是：Sandbox 扩展的是工作环境，MCP 扩展的是工具来源，provider 扩展的是模型后端，realtime 和 voice 扩展的是交互形态。

## 相关笔记

- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK 示例与学习路径]]
- [[OpenAI Agents SDK Sandbox Memory]]
- [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
