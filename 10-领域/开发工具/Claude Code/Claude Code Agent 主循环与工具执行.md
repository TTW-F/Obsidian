---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Agent Loop
  - Tool Runtime
type: area
---

# Claude Code Agent 主循环与工具执行

## 研究边界

这篇聚焦 `Claude Code` 的实际调用链：用户输入怎样进入模型、触发工具、再回到下一轮推理。

## 关键文件

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/utils/processUserInput/processUserInput.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`
- `src/hooks/useCanUseTool.tsx`

## 我当前理解的主调用链

### 1. 用户输入先被预处理

输入不是直接塞给模型，而是先经过 `processUserInput`：

- 识别 slash command
- 区分普通 prompt 和本地命令
- 注入上下文、附件、meta message
- 处理 hooks

### 2. QueryEngine 持有会话级状态

`QueryEngine.ts` 更像“会话控制器”：

- 持有 conversation messages
- 管 read file cache
- 管 usage / cost
- 管 permission denials
- 组织 system prompt、user context、tools、commands

它负责把一次输入变成一轮可执行的 agent 回合。

### 3. query.ts 负责回合内循环

`query.ts` 是真正的 agent loop：

- 向模型发起流式请求
- 处理 assistant / tool_use / tool_result
- 在工具结果返回后继续下一轮采样
- 管 compact、budget、stop hooks

这说明 Claude Code 把“会话生命周期”和“单回合状态机”拆成了两层。

### 4. 工具执行又被单独拆层

工具不是在主循环里直接跑，而是至少分成两层：

- `toolOrchestration.ts`：调度多个 tool call，决定哪些能并发、哪些要串行
- `toolExecution.ts`：包装单次工具执行，处理校验、权限、telemetry、progress、结果归一化

这种拆法很关键，因为它把“执行策略”和“单次执行细节”分开了。

### 5. 权限决策是一条独立管线

`useCanUseTool.tsx` 说明权限不是工具自己各自判断，而是统一走决策入口：

- 静态规则
- classifier
- interactive approval
- coordinator / worker 特殊分流

## 这套设计最值得学的地方

- 输入处理、会话管理、回合循环、工具执行、权限治理都不是一锅粥
- Claude Code 把 agent loop 拆成可维护的几个系统边界
- 一旦以后要接 subagent、MCP、插件，这种拆层会非常重要

## 我对这个调用链的总结

可以把它理解成：

`用户输入 -> 预处理 -> 会话编排 -> 回合循环 -> 工具调度 -> 单次工具执行 -> 权限判定 -> 结果回写 -> 下一轮推理`

## 我的理解

很多人说 agent 的核心是 tool use。
但从 Claude Code 看，更准确的说法是：

agent 的核心是“围绕 tool use 组织起来的一整套运行时”。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code 启动链路与运行模式]]
- [[../../20-主题/Agentic CLI/工具调用系统]]
- [[../../20-主题/Agentic CLI/权限与安全边界]]
