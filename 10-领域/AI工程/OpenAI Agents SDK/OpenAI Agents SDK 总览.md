---
tags:
  - 领域
  - AI工程
  - OpenAI Agents SDK
type: area
---

# OpenAI Agents SDK 总览

## 这条研究线在做什么

这组笔记围绕 `E:\AI_Writer\vendor\openai-agents-python` 建立，重点偏向“这个仓库本身是怎么组织和运行的”，尽量和通用 agent 框架笔记错开。

我更关心的不是“怎么用一个 API 快速跑 demo”，而是：

- 这套 SDK 如何把 agent 定义成运行时
- `Runner.run()` 背后的主循环如何拆层
- tools、handoffs、guardrails、sessions、tracing 如何织进同一条执行链
- Sandbox、MCP、provider 扩展怎样进入正式架构

## 研究边界

这组笔记优先记录 OpenAI Agents SDK 自己的实现特征，而不是泛讲所有 agent 框架。

也就是说：

- `10-领域` 这里保留仓库视角、源码入口和研究主线
- `20-主题` 里提炼成更稳定的执行链、运行时、扩展机制理解
- 与 `Claude Code / Agentic CLI` 的共性概念尽量少重复写

## 当前入口

- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 学习总览]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 研究路线]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 执行主线与源码入口]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK run_internal 执行链路]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK turn_resolution 决策流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tool_execution 工具执行流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK session_persistence 状态持久化]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 运行时编排]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Memory]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 示例与学习路径]]
- [[../../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 单智能体跨快照续跑]]
- [[../../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 多智能体多轮隔离]]
- [[../../../20-主题/OpenAI Agents SDK/项目卡：sandbox repo_code_review 工作流]]
- [[../../../20-主题/OpenAI Agents SDK/项目卡：sandbox vision_website_clone 工作流]]

## 这套 SDK 的定位

- 它不是单纯的 API 包装，而是一层 agent runtime
- 核心主线是：`Agent -> Runner -> run_internal -> tools / handoffs / guardrails / sessions / tracing`
- 对 OpenAI 默认走 Responses API，但模型层本身保留多 provider 扩展能力
- `SandboxAgent` 让 agent 从“调用工具”进一步进入“真实工作区执行任务”

## 我给这组笔记的定位

- `10-领域` 里记录这个仓库为什么值得读、从哪里下手
- `20-主题` 里拆执行链、状态、扩展、学习路径
- `30-地图` 里把它纳入整个知识库主线

## 我目前最关心的几个问题

- `Runner.run()` 到底如何把一轮轮执行推进下去
- `run_internal/` 为什么要拆成这么多文件
- tools、handoffs、guardrails、sessions、tracing 的边界如何划分
- Sandbox 到底只是新能力，还是新的运行范式

## 我的理解

OpenAI Agents SDK 真正值得研究的地方，不是“它能跑 agent”，而是它试图把 agent 运行过程本身做成一套可编排、可观测、可恢复、可扩展的 runtime。
