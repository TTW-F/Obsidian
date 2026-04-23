---
tags:
  - 领域
  - 开发工具
  - Claude Code
type: area
---

# Claude Code 总览

## 这是什么

这组笔记是 Claude Code 的主题入口页，负责把产品内的源码专题组织成一张可导航的总览。

这里不展开细节，主要解决两个问题：

- 如果要理解 Claude Code，应该先从哪几篇进入
- 各个专题大致落在哪些模块和能力面

## 为什么这页重要

- Claude Code 的主题很多，如果没有总入口，很容易在细分笔记之间来回跳
- 一张清楚的总览页可以先把“系统骨架”和“专题深挖”区分开
- 它也能作为后续新增笔记的回链中心，避免内容继续分散

## 如果只想快速进入，先看这几篇

1. [[Claude Code 阅读路径与关键文件入口]]
2. [[Claude Code 源码结构]]
3. [[Claude Code Agent 主循环与工具执行]]
4. [[../../../40-源码镜像/AI_Writer Vendor/AI_Writer vendor 源码镜像总览]]

这四篇最适合先抓住整体骨架。

如果需要直接对照源码目录，再从源码镜像总览跳到项目内镜像路径会更顺。

## 当前最重要的内容分组

### 运行时骨架

- [[Claude Code 启动链路与运行模式]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 启动态配置注入与 bootstrap state]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[Claude Code 模型 API 适配层]]
- [[Claude Code 提示词分层与 System Prompt 组织]]
- [[Claude Code Compact、History Snip 与长上下文收缩]]

这组笔记主要对应 `main.tsx`、`QueryEngine.ts`、`query.ts`、`context.ts` 一带的主执行链。

### 扩展与平台

- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code MCP 客户端接入链路]]
- [[Claude Code 插件加载与 Marketplace 机制]]
- [[Claude Code 命令系统与命令发现]]
- [[Claude Code 建议系统与 Advisor 机制]]

这组笔记主要对应 `skills/`、`services/mcp/`、`utils/plugins/`、`commands.ts` 这些扩展接入和能力暴露入口。

### 多代理、任务与隔离

- [[Claude Code Coordinator、Swarm 与 Subagent 机制]]
- [[Claude Code 任务系统与后台执行模型]]
- [[Claude Code Worktree、Remote Isolation 与执行隔离]]

这组笔记主要对应 `tools/AgentTool/`、`coordinator/`、`tasks/`、`utils/worktree.js` 一带的协作与隔离实现。

### 交互、观测与安全

- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code CLI Structured IO 与 Remote Transport]]
- [[Claude Code Direct Connect 会话入口]]
- [[Claude Code REPL、Ink 与交互层]]
- [[Claude Code Voice 输入、转写与语音交互链路]]
- [[Claude Code Vim 模式与键位系统]]
- [[Claude Code Hooks、Telemetry 与产品化观测]]
- [[Claude Code 文件系统与 Shell 安全模型]]

这组笔记主要对应 `bridge/`、`replLauncher.tsx`、`hooks/`、`utils/permissions/` 这些交互、观测和安全模块。

## 抽象主题回链

如果想从更抽象的层看 Claude Code，可以回到：

- [[../../../20-主题/Agentic CLI/Agentic CLI 总览]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
- [[../../../20-主题/Agentic CLI/工具调用系统]]
- [[../../../20-主题/Agentic CLI/权限与安全边界]]
- [[../../../20-主题/Agentic CLI/多代理协作]]
- [[../../../20-主题/Agentic CLI/技能、插件与扩展机制]]

## 易错点

- 容易把这页写成单纯链接列表，结果失去导航意义
- 容易把所有专题平铺，缺少层次感
- 容易在这里重复主题层的方法论，反而把产品入口页写成抽象框架页

## 相关笔记

- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 源码结构]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 总览]]
