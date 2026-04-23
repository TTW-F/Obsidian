---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 源码分析
type: area
---

# Claude Code 源码结构

## 这是什么

这篇笔记只做一件事：先抓住 Claude Code 源码的骨架，帮助后续阅读时更快定位“入口、编排、能力、治理、扩展”分别落在哪些目录。

它不是专题细节页，而是一张源码导航图。

## 为什么重要

- Claude Code 目录很多，如果没有骨架，很容易一上来就陷在局部实现里
- 先理解分层，再读具体专题，能明显减少“知道文件名但不知道它在系统里干什么”的情况
- 这页也适合作为后续细分笔记的回链入口

## 一级结构

- `main.tsx`：启动入口，负责初始化、预热、模式切换、CLI 参数解析、REPL 启动
- `commands.ts`：命令注册表，把 slash command 组织成用户入口
- `tools.ts`：工具注册表，把模型可调用能力组织成统一集合
- `Tool.ts`：工具协议、上下文、权限上下文、进度事件等核心类型
- `QueryEngine.ts`：对话主循环，负责消息、工具调用、预算、状态、持久化
- `services/`：API、MCP、LSP、analytics、plugin、compact 等服务层
- `tools/`：Bash、文件读写、Grep、Web、Agent、Skill、MCP、Task 等工具实现
- `commands/`：用户显式触发的命令入口
- `bridge/`：CLI 与 IDE / remote control 的通信桥
- `skills/`：技能加载、frontmatter 解析、技能目录管理
- `plugins/` 与 `utils/plugins/`：插件加载、校验、缓存、市场、启动检查
- `coordinator/` 与 `utils/swarm/`：多代理协作与团队机制
- `utils/permissions/`：权限模式、规则解析、危险规则识别、安全收敛

## 这些分层可以怎样理解

### 1. 用户入口层

这一层负责“人怎么进入系统”，典型对象包括 CLI 参数、slash command、交互式 REPL、远程和桥接入口。

### 2. 编排层

这一层负责“任务怎么被推进”，主要包括：

- `main.tsx`
- `QueryEngine.ts`
- `processUserInput`
- session / state / history

### 3. 能力层

这一层负责“系统能做什么”，包括：

- tools
- commands
- MCP resources
- LSP
- skills
- plugins

### 4. 治理层

这一层负责“能不能这样做、怎样长期做稳”，例如：

- permissions
- settings
- policy limits
- telemetry
- migrations

## 这份结构图最值得记住的几个点

- 它把“人用的入口”和“模型用的能力”明确拆开了
- 它有一层很强的编排层，而不是让工具直接彼此乱连
- 它把权限、设置和策略当成独立治理层，而不是零散判断
- 它给技能、插件、MCP、多代理留了正式扩展入口

## 一个具体阅读场景怎么用这页

如果我要研究 Claude Code 的多代理能力，就不应该从 `main.tsx` 一直线性读到底，而是先用这页定位：

1. 编排层大概在哪
2. 多代理目录落在哪
3. 权限和隔离属于哪层
4. 哪些是入口文件，哪些是具体实现

这样再去读 `AgentTool`、`coordinator/`、`utils/swarm/` 时，会更清楚它们在整体结构里承担什么角色。

## 易错点

- 容易直接从某个专题文件开始读，结果没有整体分层感
- 容易把命令、工具、技能、插件都当成功能点，而忽略它们属于不同层
- 容易只记目录名，不记每层到底在系统里负责什么

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 总览]]
