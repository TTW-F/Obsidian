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

这篇笔记记录 Claude Code 怎样把产品约束、运行时状态、当前任务和扩展注入组织成一套可维护的提示词系统。

这里真正要理解的，不是“怎么写 prompt”，而是 agent 运行时怎样组织自己的行为边界。

## 为什么重要

- Claude Code 实际运行时承载的，不只是用户输入，还包括产品约束、工具能力、环境状态和扩展信息
- 这些信息来源不同、优先级不同，如果混成一层，系统会很难调试和维护
- 理解这层之后，更容易看清 agent 的行为边界并不是模型“自己想出来的”，而是由提示词编排系统共同塑造的

## system prompt 为什么不能理解成固定文本

可以先把 system prompt 理解成一套按层拼装的运行时结构。

因为 Claude Code 同时要接住：

- 产品级行为规则
- 当前会话与环境状态
- 工具与命令可见性
- 用户当前输入
- skills、memory、MCP 等扩展注入

如果这些内容全塞进一段难以分辨来源的大文本里，就会很难判断某个行为到底受哪一层约束。

## 可以先怎样理解它的分层

### 1. 基础系统层

这一层定义产品身份、总体行为边界、工具使用规则和会话基本约束。

它更像平台基座，而不是针对某次任务临时写的一段说明。

### 2. 运行时上下文层

这一层会随着当前环境变化而变化，常见内容包括：

- cwd / repo 状态
- 当前可用工具
- MCP clients
- settings / permission mode
- memory 注入

这说明 system prompt 里实际上混入了大量实时状态，而不是永远不变的静态文本。

### 3. 任务输入层

用户这次输入的目标、附件、slash command 转换结果、meta message 会在更靠后的层进入。

这一层真正决定当前回合在解决什么问题。

### 4. 扩展补丁层

skills、hooks、agent definitions、custom prompt append 这些能力，更像是在核心 prompt 外继续打补丁。

也正因为如此，Claude Code 才会区分：

- custom system prompt
- append system prompt
- initial prompt
- skill / memory 注入

这些东西看起来都像“往 prompt 里加内容”，但它们并不属于同一层，也不该共享同一优先级。

## 关键入口

- `src/context.ts`
- `src/QueryEngine.ts`
- `src/utils/queryContext.ts`
- `src/utils/messages/`
- `src/utils/systemPromptType.ts`
- `src/utils/messages/systemInit.ts`

这些位置共同说明：Claude Code 没有把 prompt 当成一段固定大字符串，而是在做分层拼装。

## 一个具体场景怎么理解这层

假设当前回合同时受到这些因素影响：

- 产品级安全约束
- 当前仓库状态
- 某个 skill 的补充说明
- memory 注入
- 用户这次的具体任务

如果没有清楚的 prompt 分层，系统就很难解释：某条行为到底来自产品规则、当前环境，还是 skill 给的附加约束。

这个场景能帮助我记住，提示词组织本身就是运行时架构问题。

## 最该记住的点

- system prompt 不是一段固定文本，而是一套按层拼装的运行时结构
- 产品约束、运行时上下文、用户任务和扩展注入最好分层组织
- 一旦 skills、memory、MCP、custom prompt 都能注入系统，prompt 组织就不再是简单字符串拼接，而是配置和运行时共同决定的编排过程

## 易错点

- 容易把 system prompt 理解成固定文本
- 容易把用户输入层和系统约束层混在一起看
- 容易低估 skills、memory、custom prompt append 加进来后带来的层级复杂度
- 容易只看到“prompt 很长”，而忽略真正值得追的是 `context.ts`、`queryContext.ts`、`systemInit.ts` 这些位置怎样把产品规则、环境状态、memory 和用户任务拼到一起

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[Claude Code Compact、History Snip 与长上下文收缩]]
- [[Claude Code 建议系统与 Advisor 机制]]
