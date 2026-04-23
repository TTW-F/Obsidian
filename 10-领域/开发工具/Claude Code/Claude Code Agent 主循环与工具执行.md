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

这篇笔记记录 Claude Code 一轮任务到底怎么跑起来：用户输入怎样进入系统，怎样触发模型、工具和权限，再怎样回到下一轮推理。

这里最值得先记住的一点是，它不是一条“模型回答后顺手调工具”的简单链，而是由 `processUserInput`、`QueryEngine.ts`、`query.ts`、`toolOrchestration.ts`、`toolExecution.ts` 串起来的执行链。

## 为什么重要

- 如果这层没看清，后面看命令、权限、MCP、子代理时很容易一直混层
- Claude Code 的主循环不仅要发模型请求，还要持续接住工具结果、权限决策、预算和状态更新
- 理解这条主线后，很多分散专题页都会重新落回同一条执行链

## 关键入口

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/utils/processUserInput/processUserInput.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`
- `src/hooks/useCanUseTool.tsx`

这些文件刚好对应输入预处理、会话编排、单回合循环、工具调度、单次执行和权限决策。

## 这条主调用链可以先怎样理解

### 1. 用户输入先被预处理

输入不会直接塞给模型，而是先经过 `processUserInput`。

这层至少会处理：

- slash command 识别
- 普通 prompt 和本地命令区分
- 上下文、附件、meta message 注入
- hooks 触发

所以真正进入主循环前，系统已经先做了一轮输入编排。

### 2. `QueryEngine` 持有会话级状态

可以先把 `QueryEngine.ts` 理解成“会话控制器”。

它负责的通常是：

- conversation messages
- read file cache
- usage / cost
- permission denials
- system prompt、user context、tools、commands 的收拢

它的职责更偏“把一次输入组织成一轮可执行的 agent 回合”。

### 3. `query.ts` 负责回合内循环

`query.ts` 更像真正的单回合状态机。

它会持续处理：

- 向模型发起流式请求
- assistant / tool_use / tool_result 的往返
- 工具结果返回后的下一轮采样
- compact、budget、stop hooks

这说明 Claude Code 把“会话生命周期”和“单回合状态机”拆成了两层。

### 4. 工具执行又被单独拆成两层

工具不会在主循环里直接跑，而是至少分成：

- `toolOrchestration.ts`：调度多个 tool call，决定哪些能并发、哪些要串行
- `toolExecution.ts`：包装单次工具执行，处理校验、权限、telemetry、progress、结果归一化

这样拆开后，主循环负责推进回合，工具层负责把一次调用稳稳落地。

### 5. 权限决策是一条独立管线

`useCanUseTool.tsx` 说明权限不是每个工具各自判断，而是统一走决策入口。

这里会牵涉：

- 静态规则
- classifier
- interactive approval
- coordinator / worker 特殊分流

## 一个具体场景怎么理解这条链

假设用户要求“找出仓库里相关文件、修改实现、再运行验证命令”。

这时系统大致会经历：

1. 输入预处理识别请求和附件上下文
2. `QueryEngine` 组织本轮会话级上下文
3. `query.ts` 向模型采样，拿到 tool use
4. 工具调度层决定读类和写类工具怎样排布
5. 单次执行层逐个工具做权限、执行和结果包装
6. 工具结果回流后，再进入下一轮推理

这个场景能帮助我记住：Claude Code 的“agent loop”本质上是一个持续收束和再推进的闭环。

## 最值得记住的点

- 输入处理、会话管理、回合循环、工具执行、权限治理都不是一锅粥
- `QueryEngine.ts` 和 `query.ts` 虽然都重要，但并不是同一层
- Claude Code 明确把 `toolOrchestration.ts` 和 `toolExecution.ts` 分开，说明“调度多个工具”和“执行单个工具”在实现上是两层问题

## 易错点

- 容易把 `QueryEngine.ts` 和 `query.ts` 看成同一层
- 容易把工具执行理解成“模型发出 tool_use 后直接运行工具”
- 容易把权限系统理解成工具内部的小判断，而不是独立决策管线
- 容易忽视 `processUserInput` 的位置，好像用户输入会直接进入主循环，实际 Claude Code 在进入 `QueryEngine` 前已经先做了一层输入编排

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 启动链路与运行模式]]
- [[../../20-主题/Agentic CLI/工具调用系统]]
- [[../../20-主题/Agentic CLI/权限与安全边界]]
