---
tags:
  - 领域
  - AI工程
  - OpenAI Agents SDK
type: area
---

# OpenAI Agents SDK 总览

这组笔记围绕 `E:\AI_Writer\vendor\openai-agents-python` 建立，重点偏向“这个仓库本身是怎么组织和运行的”，尽量和通用 agent 框架笔记错开。

## 现有笔记

- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 学习总览]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 执行主线与源码入口]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK run_internal 执行链路]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 运行时编排]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 示例与学习路径]]

## 这套 SDK 的定位

- 它不是单纯的 API 包装，而是一层 agent runtime。
- 核心主线是：`Agent -> Runner -> run_internal -> tools / handoffs / guardrails / sessions / tracing`。
- 对 OpenAI 默认走 Responses API，但模型层本身保留多 provider 扩展能力。
- 0.14 之后的重点增量之一是 `SandboxAgent`，把 agent 从“调用工具”推进到“进入真实工作区执行任务”。

## 这组笔记的写法边界

我会优先记录：

- 仓库目录与源码入口
- `Runner.run()` 背后的执行链路
- `run_internal/` 的职责切分
- examples 与 docs 的学习路径
- OpenAI Agents Python 自己的实现特征

我会尽量少写：

- 通用 agent 框架史
- 脱离本仓库的抽象理论
- 已经在其他 agent 笔记里出现过的共性概念
