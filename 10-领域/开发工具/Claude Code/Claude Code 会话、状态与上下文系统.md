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

## 这是什么

这篇笔记记录 Claude Code 怎样把会话、状态、上下文和记忆组织成一套能持续跑长任务的基础设施。

这里最值得先分清的一点是：Claude Code 里的“状态”不是一个总桶，而是多层不同用途的状态组合。

## 为什么重要

- 如果只盯着 `messages[]`，很容易误以为 agent 系统的会话管理只是“保存聊天记录”
- Claude Code 实际上同时在管理会话推进、产品状态、文件缓存、历史持久化和 memory 注入
- 长会话、长任务和状态恢复是否稳定，很大程度取决于这套基础设施是否分层清楚

## 关键入口

- `src/QueryEngine.ts`
- `src/state/AppStateStore.ts`
- `src/context.ts`
- `src/memdir/`
- `src/history.ts`
- `src/utils/sessionStorage.ts`

这些位置很适合用来区分“会话推进状态”“产品状态”“历史 / memory / 上下文构建”各自的职责。

## Claude Code 里的状态至少分成哪几层

可以先按下面几层理解：

- 会话消息状态
- UI / AppState 状态
- 文件读取缓存
- transcript / session persistence
- memory / memdir
- MCP、plugins、permissions 等运行时状态

这说明它不是简单地把 `messages[]` 存起来就结束了。

## 会话状态和产品状态为什么不能混成一层

### `QueryEngine.ts`

这层更接近“会话推进运行时”。

它关心的通常是：

- mutable messages
- abort controller
- usage / cost
- permission denials
- read file cache
- 每轮 `submitMessage` 的局部轨迹

### `AppStateStore.ts`

这层更接近完整产品状态树。

它管理的不只是对话，还会碰到：

- settings
- toolPermissionContext
- MCP clients
- plugins
- agentDefinitions
- tasks
- notifications
- thinking / bridge / elicitation

这两个入口放在一起看，就能更清楚地分出“会话运行时”和“应用状态树”。

## 上下文为什么是运行时产物

`context.ts` 很值得单独记住，因为它说明 system context 和 user context 不是固定模板，而是动态构建的。

在 Claude Code 里，上下文通常会结合：

- 当前 cwd / repo 环境
- 工具与命令可用性
- session 状态
- memory 内容
- 用户与系统层面的附加上下文

这意味着“上下文”本身就是运行时生成结果，而不是预先写死的一段 prompt。

## 历史、持久化和记忆为什么要分开看

从 `history.ts`、`sessionStorage.ts`、`memdir/` 这些位置可以看出，Claude Code 很重视：

- 恢复历史会话
- 记录 transcript
- 从交互中抽取 memory
- 在后续回合中重新注入相关记忆

这些都和“保留过去”有关，但不是同一个问题。

## 一个具体场景怎么理解这套分层

如果用户开了一个很长的编码任务，中间读了很多文件、切换了工具模式、还调用了 MCP 和子代理，那么系统至少要同时回答：

- 当前对话消息怎么继续推进
- 哪些产品状态要同步到 UI
- 哪些文件读取结果应该复用缓存
- 哪些历史要持久化
- 哪些 memory 值得在后续轮次重新注入

这个场景能帮助我记住：会话、状态、上下文和记忆虽然相关，但它们处理的不是同一层问题。

## 易错点

- 容易把 `QueryEngine.ts` 当成整个系统唯一的状态中心
- 容易把上下文理解成固定 prompt，而不是动态拼装结果
- 容易把 history、session persistence、memory 当成同一回事

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
