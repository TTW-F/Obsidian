---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Agentic CLI
type: area
---

# Claude Code 总览

## 这条研究线在做什么

这里放我对 `Claude Code` 这类 agentic coding CLI 的长期研究。

重点不是“记住一个项目”，而是借它学习一整套系统能力：

- 终端里的 AI 编码代理如何组织能力
- 工具调用、权限控制、上下文管理如何协同
- 多代理、技能、插件、桥接这些扩展机制如何落地

## 研究边界

这组笔记优先记录 `Claude Code` 源码研究与实现启发，不主动承担“通用 agent 框架大全”的角色，避免和别的研究线重复。

也就是说：

- `10-领域` 这里保留项目入口和源码观察
- `20-主题` 里提炼成可迁移的方法论
- 同一内容尽量不在两个层级重复写

## 当前入口

### 先从这里进入

- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 源码结构]]
- [[Claude Code Agent 主循环与工具执行]]

### 运行时骨架

- [[Claude Code 启动链路与运行模式]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[Claude Code 模型 API 适配层]]
- [[Claude Code 提示词分层与 System Prompt 组织]]
- [[Claude Code Compact、History Snip 与长上下文收缩]]

### 扩展与平台

- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code MCP 客户端接入链路]]
- [[Claude Code 插件加载与 Marketplace 机制]]
- [[Claude Code 命令系统与命令发现]]
- [[Claude Code 建议系统与 Advisor 机制]]

### 多代理、任务与隔离

- [[Claude Code Coordinator、Swarm 与 Subagent 机制]]
- [[Claude Code 任务系统与后台执行模型]]
- [[Claude Code Worktree、Remote Isolation 与执行隔离]]

### 交互、观测与安全

- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code REPL、Ink 与交互层]]
- [[Claude Code Hooks、Telemetry 与产品化观测]]
- [[Claude Code 文件系统与 Shell 安全模型]]

### 抽象主题回链

- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 总览]]
- [[../../../20-主题/Agentic CLI/工具调用系统]]
- [[../../../20-主题/Agentic CLI/权限与安全边界]]
- [[../../../20-主题/Agentic CLI/多代理协作]]
- [[../../../20-主题/Agentic CLI/技能、插件与扩展机制]]

## 为什么值得长期研究

- 它不是单一功能工具，而是一整套 agent 产品工程
- 它把模型、工具、权限、状态、扩展都放进同一个终端系统里
- 很多实现决策都能迁移到别的 agent 产品、CLI、IDE 助手和自动化系统里

## 我给这组笔记的定位

- `10-领域` 里记录与 Claude Code 直接相关的研究入口
- `20-主题` 里提炼成可迁移的方法论
- `30-地图` 里负责把这些内容串起来

如果只想快速进入，不必先逐篇读完，优先看：

1. [[Claude Code 阅读路径与关键文件入口]]
2. [[Claude Code 源码结构]]
3. [[Claude Code Agent 主循环与工具执行]]

## 我目前最关心的几个问题

- 一个成熟的 coding agent 到底如何组织主循环
- 工具系统和命令系统为什么要分层
- 权限系统如何既保守又不妨碍执行力
- 多代理、技能、插件这些扩展能力如何纳入统一治理

## 后续可继续补充

- Claude Code 的模型选择、effort 与 thinking 配置协同
- Claude Code 的内存提取与 memory 注入链路
- 从 Claude Code 反推 agent 工具设计原则

## 我的理解

`Claude Code` 的价值不只在“能写代码”，而在于它把 agent 系统里最难的几块东西放进了一个可运行、可扩展、可治理的产品里。
