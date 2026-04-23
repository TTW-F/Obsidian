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

## 这是什么

这篇记的是 `Claude Code` 一轮任务到底怎么跑起来：用户输入怎样进入系统，怎样触发模型、工具、权限，再怎样回到下一轮推理。

我现在先把它记成一条调用链，而不是一堆零散模块。

## 为什么重要

如果这一层没看清，后面看命令、权限、MCP、子代理时就会一直混。

对我来说，这篇最重要的价值是回答两个问题：

- Claude Code 到底把哪些事放进了主循环
- 哪些能力又被故意拆到主循环之外

## 关键文件

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/utils/processUserInput/processUserInput.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`
- `src/hooks/useCanUseTool.tsx`

## 主调用链

### 1. 用户输入先被预处理

输入不是直接塞给模型，而是先经过 `processUserInput`：

- 识别 slash command
- 区分普通 prompt 和本地命令
- 注入上下文、附件、meta message
- 处理 hooks

### 2. QueryEngine 持有会话级状态

我现在更倾向把 `QueryEngine.ts` 理解成“会话控制器”：

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

这样拆开后，主循环负责推进回合，工具层负责把一次调用稳稳落地。

### 5. 权限决策是一条独立管线

`useCanUseTool.tsx` 说明权限不是工具自己各自判断，而是统一走决策入口：

- 静态规则
- classifier
- interactive approval
- coordinator / worker 特殊分流

## 这条链路里最值得记住的点

- 输入处理、会话管理、回合循环、工具执行、权限治理都不是一锅粥
- Claude Code 把 agent loop 拆成可维护的几个系统边界
- 一旦以后要接 subagent、MCP、插件，这种拆层会非常重要

## 一句话记法

可以把它理解成：

`用户输入 -> 预处理 -> 会话编排 -> 回合循环 -> 工具调度 -> 单次工具执行 -> 权限判定 -> 结果回写 -> 下一轮推理`

## 易错点

- 不要把 `QueryEngine.ts` 和 `query.ts` 看成同一层。
  前者更像会话控制器，后者更像单回合状态机。
- 不要把工具执行理解成“模型发出 tool_use 后直接运行工具”。
  中间还有调度、权限、校验、进度和结果归一化。
- 不要把权限系统理解成工具内部的小判断。
  在 Claude Code 里，它已经是一条独立插入执行链的决策管线。

## 我的理解

很多人说 agent 的核心是 tool use。
但从 Claude Code 看，更准确的说法是：

agent 的核心是“围绕 tool use 组织起来的一整套运行时”。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 启动链路与运行模式]]
- [[../../20-主题/Agentic CLI/工具调用系统]]
- [[../../20-主题/Agentic CLI/权限与安全边界]]
