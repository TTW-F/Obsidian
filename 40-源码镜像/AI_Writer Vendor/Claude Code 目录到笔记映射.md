---
tags:
  - 源码镜像
  - Claude Code
  - 映射
type: note
---

# Claude Code 目录到笔记映射

## 这是什么

这页把 `40-源码镜像/AI_Writer Vendor/claude-code/src` 里的主要目录，映射到当前库里已经整理好的 Claude Code 笔记。

它的作用不是代替阅读路径，而是减少“看到目录却不知道该回哪篇笔记”的来回切换。

## 推荐先看哪几组

- 想抓主循环：先看 `query / services / tools / state / context`
- 想抓扩展机制：先看 `skills / plugins / commands / services / bridge`
- 想抓多代理：先看 `tools / coordinator / tasks`
- 想抓交互与产品层：先看 `ink / bridge / hooks / screens / components`

## 目录到笔记映射

### 入口与启动

- `main.tsx`、`entrypoints/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 启动链路与运行模式]]
  - [[../../10-领域/开发工具/Claude Code/Claude Code 阅读路径与关键文件入口]]

### 交互层

- `ink/`、`components/`、`screens/`、`replLauncher.tsx`
  - [[../../10-领域/开发工具/Claude Code/Claude Code REPL、Ink 与交互层]]

- `bridge/`、`remote/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Bridge、Remote 与 IDE 集成]]

- `cli/`、`remoteIO.ts`、`structuredIO.ts`、`transports/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code CLI Structured IO 与 Remote Transport]]

- `server/`、`createDirectConnectSession.ts`、`directConnectManager.ts`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Direct Connect 会话入口]]

- `voice/`、`hooks/useVoice*.ts`、`services/voiceStreamSTT.ts`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Voice 输入、转写与语音交互链路]]

- `vim/`、`keybindings/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Vim 模式与键位系统]]

### 主循环与运行时

- `query/`、`QueryEngine.ts`、`query.ts`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Agent 主循环与工具执行]]

- `services/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 输入预处理、工具调度与权限插入]]
  - [[../../10-领域/开发工具/Claude Code/Claude Code 模型 API 适配层]]

- `context/`、`context.ts`、`state/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 会话、状态与上下文系统]]

- `bootstrap/state.ts`、`main.tsx` 里的 settings / remote 注入、`cli/print.ts` 的 flag settings 更新
  - [[../../10-领域/开发工具/Claude Code/Claude Code 启动态配置注入与 bootstrap state]]

- `assistant/`、`memdir/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Compact、History Snip 与长上下文收缩]]

### 工具与命令

- `tools/`、`Tool.ts`、`tools.ts`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Agent 主循环与工具执行]]
  - [[../../20-主题/Agentic CLI/工具调用系统]]

- `commands/`、`commands.ts`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 命令系统与命令发现]]

### Prompt、上下文压缩与建议

- `utils/`、`constants/`、`schemas/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 提示词分层与 System Prompt 组织]]

- `buddy/`、`moreright/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 建议系统与 Advisor 机制]]

### 安全、权限与隔离

- `hooks/`、`services/permissions`、`utils/permissions`、`utils/shell`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 文件系统与 Shell 安全模型]]

- `tasks/`、`remote/`、`upstreamproxy/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Worktree、Remote Isolation 与执行隔离]]
  - [[../../10-领域/开发工具/Claude Code/Claude Code 任务系统与后台执行模型]]

### 扩展机制

- `skills/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 扩展总线：Skills、Plugins、MCP]]
  - [[../../20-主题/Agentic CLI/技能、插件与扩展机制]]

- `plugins/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 插件加载与 Marketplace 机制]]
  - [[../../10-领域/开发工具/Claude Code/Claude Code 扩展总线：Skills、Plugins、MCP]]

- `services/mcp`、`mcp` 相关实现
  - [[../../10-领域/开发工具/Claude Code/Claude Code MCP 客户端接入链路]]
  - [[../../10-领域/开发工具/Claude Code/Claude Code 扩展总线：Skills、Plugins、MCP]]

### 多代理与编排

- `coordinator/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Coordinator、Swarm 与 Subagent 机制]]
  - [[../../20-主题/Agentic CLI/多代理协作]]

- `tasks/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code 任务系统与后台执行模型]]

### 观测与产品化

- `hooks/`、`bootstrap/`
  - [[../../10-领域/开发工具/Claude Code/Claude Code Hooks、Telemetry 与产品化观测]]

## 现在最值得继续补的缺口

- `assistant/` 与 `buddy/` 之间的用户侧工作流还可以继续拆细
- `bootstrap/` 里除 `state.ts` 之外的初始化依赖顺序还可以单独补一页
- `screens/`、`components/` 的交互分层还没有独立入口

## 相关笔记

- [[AI_Writer vendor 源码镜像总览]]
- [[../../10-领域/开发工具/Claude Code/Claude Code 总览]]
- [[../../10-领域/开发工具/Claude Code/Claude Code 阅读路径与关键文件入口]]
