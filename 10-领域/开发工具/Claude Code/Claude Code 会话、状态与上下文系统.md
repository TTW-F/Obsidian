---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 会话
  - 状态管理
  - 上下文
type: area
---

# Claude Code 会话、状态与上下文系统

## 研究边界

这篇只关注 `Claude Code` 如何维护会话、状态和上下文，不展开成通用 agent memory 理论。

## 我研究这部分时最关心什么

- 系统里到底有几种状态
- 会话状态和产品状态如何分层
- 上下文是静态模板还是动态生成
- 历史、记忆、缓存如何服务长期任务

## 关键文件

- `src/QueryEngine.ts`
- `src/state/AppStateStore.ts`
- `src/context.ts`
- `src/memdir/`
- `src/history.ts`
- `src/utils/sessionStorage.ts`

## 我看到的几个层次

Claude Code 里的“状态”不是一个东西，而是至少分成几层：

- 会话消息状态
- UI / AppState 状态
- 文件读取缓存
- transcript / session persistence
- memory / memdir
- MCP、plugins、permissions 等运行时状态

这说明它不是简单地把 `messages[]` 存起来就结束了。

## 会话状态

`QueryEngine.ts` 持有的是偏“会话推进”所需的状态：

- mutable messages
- abort controller
- usage / cost
- permission denials
- read file cache
- 每轮 submitMessage 的局部轨迹

这层更接近“agent conversation runtime”。

## AppState 状态

`state/AppStateStore.ts` 反映的是更完整的产品状态树。

从职责上看，它要管的不只是对话，还包括：

- settings
- toolPermissionContext
- MCP clients
- plugins
- agentDefinitions
- tasks
- notifications
- thinking / bridge / elicitation

这说明 Claude Code 本质上是一个完整 TUI 应用，而不是只包一层聊天循环。

## 上下文构建

`context.ts` 说明 system context 和 user context 不是固定模板，而是动态收集的。

Claude Code 在拼上下文时，会考虑：

- 当前 cwd / repo 环境
- 工具与命令可用性
- session 状态
- memory 内容
- 用户与系统层面的附加上下文

这意味着“上下文”本身也是运行时产物。

## 持久化与记忆

从 `history.ts`、`sessionStorage.ts`、`memdir/` 来看，Claude Code 很重视：

- 恢复历史会话
- 记录 transcript
- 从交互中抽取 memory
- 在后续回合中重新注入相关记忆

这套设计明显不是为了单轮问答，而是为了长期任务连续性。

## 我提炼出的实现启发

- agent 系统里的“状态”最好按职责拆层，而不是一个大对象全装
- 会话消息、产品状态、长期记忆、文件缓存不应混成同一抽象
- 上下文生成应该是动态流程，而不是静态 prompt 模板

## 如果继续往下读

我会继续关注：

1. QueryEngine 和 AppStateStore 的边界在哪里
2. memory / history / transcript 三者如何协同
3. 上下文构建是否有压缩、筛选、注入策略
4. 长会话下状态收缩如何避免模型上下文爆炸

## 我的理解

Claude Code 的稳定性，很大一部分不是来自模型本身，而是来自这套会话、状态、上下文的基础设施。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
