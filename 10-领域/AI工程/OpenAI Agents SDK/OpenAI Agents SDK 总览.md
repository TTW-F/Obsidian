---
tags:
  - 领域
  - AI工程
  - OpenAI Agents SDK
type: area
---

# OpenAI Agents SDK 总览

## 这是什么

这组笔记围绕 `40-源码镜像/AI_Writer Vendor/openai-agents-python` 展开，重点是把这个仓库里真正稳定、可复用的实现知识拆成独立笔记。

这里的角色不是“再讲一遍 SDK 文档”，而是作为领域入口，把源码主线、专题笔记和案例卡串成一张可回看的地图。

## 为什么重要

- OpenAI Agents SDK 的主题很多，如果没有入口页，很容易在运行时、sandbox、模型层和案例卡之间来回跳
- 这组笔记既有领域入口，也有主题提炼，如果不先分清角色，内容会越来越混
- 一个清楚的总览页可以帮我先决定：现在应该看主线、看示例，还是钻某个专题

## 这组笔记主要关注什么

我现在最关心的几条主线是：

- 这套 SDK 如何把 agent 定义成运行时
- `Runner.run()` 背后的主循环如何拆层
- tools、handoffs、guardrails、sessions、tracing 如何织进同一条执行链
- Sandbox、MCP、provider 扩展怎样进入正式架构

## 这组笔记和 `20-主题` 的分工

我现在会这样分：

- `10-领域` 这里保留仓库视角、源码入口和研究主线
- `20-主题` 里提炼成更稳定的运行时、执行链、扩展机制理解
- 与 `Claude Code / Agentic CLI` 的共性概念尽量少在这里重复写

换句话说，这里更像“从仓库进入”，`20-主题` 更像“沉淀成可迁移知识”。

## 当前最重要的入口

- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 学习总览]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 研究路线]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 示例与学习路径]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 执行主线与源码入口]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK run_internal 执行链路]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK turn_resolution 决策流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK handoff 交接语义与输入迁移]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tool_execution 工具执行流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK session_persistence 状态持久化]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tracing 结构与 span 语义]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Realtime 会话与事件流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 模型抽象层与 Provider 路由]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP 连接管理与调用链]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP Transport 与 Session 建立]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP 请求串行化与共享 Session 语义]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP Message Handler 与 Session 消息流]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Memory]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[../../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 单智能体跨快照续跑]]
- [[../../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 多智能体多轮隔离]]
- [[../../../20-主题/OpenAI Agents SDK/项目卡：sandbox repo_code_review 工作流]]
- [[../../../20-主题/OpenAI Agents SDK/项目卡：sandbox vision_website_clone 工作流]]
- [[../../../40-源码镜像/AI_Writer Vendor/AI_Writer vendor 源码镜像总览]]

## 三个最适合先看的入口页

- `学习总览`：先建立这套 SDK 的整体心智模型
- `研究路线`：安排整组笔记的推荐学习顺序
- `示例与学习路径`：按 examples/ 的能力分组来选示例

这三篇一起看，最容易先抓住“整体结构 + 推荐阅读顺序 + 示例入口”。

## 这套 SDK 最值得先记住的定位

- 它不是单纯的 API 包装，而是一层 agent runtime
- 核心主线是：`Agent -> Runner -> run_internal -> tools / handoffs / guardrails / sessions / tracing`
- 对 OpenAI 默认走 Responses API，但模型层本身保留多 provider 扩展能力
- `SandboxAgent` 让 agent 从“调用工具”进一步进入“真实工作区执行任务”

## 一个具体使用场景怎么理解这组笔记

如果我想回答“这套 SDK 为什么不像一个普通工具库”，最好的顺序不是直接看某篇 sandbox 案例，而是：

1. 先看执行主线和 `run_internal`
2. 再看 tools、handoff、session、tracing 这些运行时专题
3. 最后再回到 sandbox 和项目卡

这个顺序能帮助我先抓骨架，再看具体工作流。

## 易错点

- 容易把这组笔记写成“另一本官方文档”，结果失去自己的研究价值
- 容易把领域入口和主题笔记混写，导致层次越来越乱
- 容易一上来只看案例卡，却没有先建立运行时主线

## 我的理解

OpenAI Agents SDK 真正值得研究的地方，不是“它能跑 agent”，而是它试图把 agent 运行过程本身做成一套可编排、可观测、可恢复、可扩展的 runtime。

这组总览页的价值，就是帮我从仓库入口更稳地走进这条主线。

## 相关笔记

- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 学习总览]]
- [[../../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 运行时编排]]
- [[../../AI工程总览]]
