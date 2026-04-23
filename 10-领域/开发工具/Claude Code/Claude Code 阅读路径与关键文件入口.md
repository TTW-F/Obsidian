---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 阅读路径
  - 源码入口
type: area
---

# Claude Code 阅读路径与关键文件入口

## 这是什么

这页专门负责两件事：

- 帮我决定“下一步先读哪里”
- 把各专题对应到关键源码入口

它不是通用研究方法，而是一张面向 Claude Code 仓库的阅读导航图。

## 为什么重要

- Claude Code 文件和目录很多，如果没有阅读顺序，很容易一上来就陷进局部实现
- 把专题和源码入口映射起来之后，读代码时更容易保持方向感
- 这页也适合在“时间有限”时快速决定最值得先读的几个点

## 当前源码镜像位置

- 镜像总览：[[../../../40-源码镜像/AI_Writer Vendor/AI_Writer vendor 源码镜像总览]]
- 代码根目录：`40-源码镜像/AI_Writer Vendor/claude-code`

## 推荐阅读顺序

### 第一段：先建立启动到回合推进的主线

1. `src/main.tsx`
2. `src/commands.ts`
3. `src/tools.ts`
4. `src/Tool.ts`
5. `src/QueryEngine.ts`
6. `src/query.ts`

这一段读完，基本能回答：

- 系统从哪里启动
- 命令和工具怎么分层
- 一轮 agent 回合怎么推进

### 第二段：再补输入、权限和状态中间层

1. `src/utils/processUserInput/processUserInput.ts`
2. `src/services/tools/toolOrchestration.ts`
3. `src/services/tools/toolExecution.ts`
4. `src/hooks/useCanUseTool.tsx`
5. `src/state/AppStateStore.ts`
6. `src/context.ts`

这一段读完，基本能回答：

- 输入进入主循环前发生了什么
- 工具如何调度
- 权限如何插入执行链
- 状态和上下文如何组织

### 第三段：最后看扩展和多代理入口

1. `src/services/mcp/client.ts`
2. `src/skills/loadSkillsDir.ts`
3. `src/utils/plugins/pluginLoader.ts`
4. `src/tools/AgentTool/loadAgentsDir.ts`
5. `src/tools/AgentTool/AgentTool.tsx`
6. `src/coordinator/coordinatorMode.ts`

这一段读完，基本能回答：

- 外部能力怎么接入
- skills / plugins / MCP 如何共存
- 多代理和 coordinator 如何落地

## 主题到源码入口的映射

### 启动与模式

- `src/main.tsx`
- `src/replLauncher.tsx`
- `src/interactiveHelpers.tsx`
- `src/entrypoints/`

对应笔记：

- [[Claude Code 启动链路与运行模式]]
- [[Claude Code REPL、Ink 与交互层]]

### 主循环与工具执行

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`

对应笔记：

- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 输入预处理、工具调度与权限插入]]

### 状态、上下文、Prompt

- `src/state/AppStateStore.ts`
- `src/context.ts`
- `src/utils/queryContext.ts`
- `src/utils/messages/`

对应笔记：

- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 提示词分层与 System Prompt 组织]]

### 安全与隔离

- `src/utils/permissions/`
- `src/utils/shell/`
- `src/utils/powershell/`
- `src/utils/sandbox/`
- `src/utils/worktree.js`

对应笔记：

- [[Claude Code 文件系统与 Shell 安全模型]]
- [[Claude Code Worktree、Remote Isolation 与执行隔离]]

### 扩展与平台接口

- `src/services/mcp/client.ts`
- `src/skills/loadSkillsDir.ts`
- `src/utils/plugins/pluginLoader.ts`
- `src/utils/plugins/loadPluginCommands.ts`

对应笔记：

- [[Claude Code MCP 客户端接入链路]]
- [[Claude Code 插件加载与 Marketplace 机制]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]

### 多代理与任务

- `src/tools/AgentTool/`
- `src/utils/swarm/`
- `src/coordinator/`
- `src/tasks/`

对应笔记：

- [[Claude Code Coordinator、Swarm 与 Subagent 机制]]
- [[Claude Code 任务系统与后台执行模型]]

## 如果时间很少

只读这 6 个文件也足够先建立整体图景：

1. `src/main.tsx`
2. `src/Tool.ts`
3. `src/tools.ts`
4. `src/QueryEngine.ts`
5. `src/query.ts`
6. `src/services/mcp/client.ts`

读完这 6 个文件后，再回到专题笔记补细节，效率通常更高。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
