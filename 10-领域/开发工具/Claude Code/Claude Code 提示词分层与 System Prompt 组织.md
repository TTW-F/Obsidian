---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Prompt
  - System Prompt
type: area
---

# Claude Code 提示词分层与 System Prompt 组织

## 这是什么

这篇记的是 `Claude Code` 怎样把 prompt 组织成一套可维护的运行时结构。

我现在先不把它理解成“写 prompt 的技巧”，而把它理解成“系统怎样组织自己的思考边界”。

## 为什么这块重要

Claude Code 不是单一 prompt 在工作。

它要同时承载：

- 产品级行为约束
- 当前会话上下文
- 工具与命令可见性
- 用户输入
- skills / memory / MCP 等附加信息

所以 prompt 组织本身就是运行时架构问题。

## 关键模块

从入口和命名上看，相关能力分散在这些地方：

- `src/context.ts`
- `src/QueryEngine.ts`
- `src/utils/queryContext.ts`
- `src/utils/messages/`
- `src/utils/systemPromptType.ts`
- `src/utils/messages/systemInit.ts`

这说明 Claude Code 没有把 prompt 当成一段固定大字符串，而是在做分层拼装。

## 我现在先这样理解它的分层

### 1. 基础系统层

这一层负责定义产品身份、总体行为边界、工具使用规则和会话基本约束。

它更像平台基座，而不是某次任务的局部提示。

### 2. 运行时上下文层

这一层会随着当前环境变化而变化，例如：

- cwd / repo 状态
- 可用工具
- MCP clients
- settings / permission mode
- memory 注入

这说明 system prompt 里其实混入了大量“实时状态”。

### 3. 任务输入层

用户这次输入的目标、附件、slash command 转换结果、meta message，会在更靠后的层进入。

这层决定当前回合在做什么。

### 4. 扩展补丁层

skills、hooks、agent definitions、custom prompt append 这些能力，像是在核心 prompt 外再打补丁。

这也是为什么 Claude Code 要认真区分：

- custom system prompt
- append system prompt
- initial prompt
- skill / memory 注入

## 这里最值得记住的点

- 提示词越复杂，越需要模块化，不然很快不可维护
- 不同来源的 prompt 信息需要不同优先级
- 产品 prompt 和任务 prompt 混成一层时，调试会非常痛苦

## 易错点

- 不要把 system prompt 理解成一段固定文本。
  在 Claude Code 里，它明显混入了大量运行时状态。
- 不要把用户输入层和系统约束层混在一起看。
  两层来源不同，优先级也不同。
- 一旦把 skills、memory、custom prompt append 都加进来，prompt 组装就不再是简单字符串拼接。

## 我的理解

Claude Code 的 prompt 组织方式提醒我，agent 产品的“思考边界”并不只由模型决定，而是由 prompt 编排系统决定。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 建议系统与 Advisor 机制]]
