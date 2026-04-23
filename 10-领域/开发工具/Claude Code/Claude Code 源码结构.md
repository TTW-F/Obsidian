---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 源码分析
type: area
---

# Claude Code 源码结构

## 这份材料是什么

我当前研究的对象是 `E:\AI_Writer\vendor\claude-code` 里的源码快照。

它对我最有价值的地方，不是“看 Anthropic 写了什么功能”，而是看一个成熟 agentic CLI 如何把这些能力拆成可维护的系统。

## 我读这份源码时的关注点

我不是平均地看所有目录，而是重点追这几个问题：

- 系统从哪里启动
- 一轮任务是怎么推进的
- 工具、命令、权限、状态怎么互相接上
- 扩展能力是怎么接进来的

## 我先抓到的一级结构

- `main.tsx`：启动入口，负责初始化、预取、模式切换、CLI 参数解析、REPL 启动
- `commands.ts`：命令注册表，把 slash command 组织成一套用户入口
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

## 我看到的关键分层

### 1. 用户入口层

- CLI 参数
- slash command
- 交互式 REPL
- 远程 / 桥接入口

### 2. 编排层

- `main.tsx`
- `QueryEngine.ts`
- `processUserInput`
- session / state / history

### 3. 能力层

- tools
- commands
- MCP resources
- LSP
- skills
- plugins

### 4. 治理层

- permissions
- settings
- policy limits
- telemetry
- migrations

## 这份结构最值得学的地方

- 它把“人用的入口”和“模型用的能力”明确拆开了
- 它有很强的编排层，而不是让工具直接彼此乱连
- 它把权限、设置、策略当成独立治理层，而不是几个零散判断
- 它给扩展机制留了正式入口，而不是在核心代码里不断打补丁

## 我对这个项目的第一印象

- 它不是一个“LLM 外壳”，而是一个很重的系统工程产品
- 设计重点不是单次回答，而是长会话、长任务、长生命周期
- 很多设计都在解决真实工程问题：启动速度、权限安全、上下文膨胀、扩展冲突、多代理协调

## 如果我要继续往下读

我会优先按这条顺序：

1. `src/main.tsx`
2. `src/QueryEngine.ts`
3. `src/Tool.ts`
4. `src/tools.ts`
5. `src/commands.ts`
6. 权限、多代理、技能、插件相关目录

因为这条路径最容易先把“系统骨架”抓出来。

## 值得继续深挖的文件

- `src/main.tsx`
- `src/QueryEngine.ts`
- `src/Tool.ts`
- `src/tools.ts`
- `src/commands.ts`
- `src/tools/AgentTool/loadAgentsDir.ts`
- `src/skills/loadSkillsDir.ts`
- `src/utils/permissions/permissionSetup.ts`

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code 命令系统与命令发现]]
- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[Claude Code 模型 API 适配层]]
- [[Claude Code Coordinator、Swarm 与 Subagent 机制]]
- [[Claude Code Compact、History Snip 与长上下文收缩]]
- [[Claude Code Hooks、Telemetry 与产品化观测]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 总览]]
- [[../../../20-主题/Agentic CLI/工具调用系统]]
- [[../../../20-主题/Agentic CLI/权限与安全边界]]
- [[../../../20-主题/Agentic CLI/多代理协作]]
- [[../../../20-主题/Agentic CLI/技能、插件与扩展机制]]
