---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 输入处理
  - Tool Orchestration
  - 权限
type: area
---

# Claude Code 输入预处理、工具调度与权限插入

## 这是什么

这篇笔记记录 Claude Code 主循环外几层很关键的中间层：输入怎样被预处理，多个工具怎样被调度，权限又怎样插进执行链。

这些层不是表面功能，但很大程度决定系统最后是不是可维护、可扩展、可治理。

## 为什么重要

- 很多 agent 原型后面变难维护，不是因为模型不够强，而是因为输入路径混乱、工具执行直接耦合在主循环里、权限逻辑散落在各处
- Claude Code 值得学的地方，正是它把这些横切复杂度拆成了几层清楚的中间层
- 一旦这些层清楚了，后面接 skills、MCP、plugins、subagent 时会稳很多

## 关键入口

- `src/utils/processUserInput/processUserInput.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`
- `src/hooks/useCanUseTool.tsx`
- `src/utils/permissions/`

这几个位置刚好对应输入、调度、执行、权限四个不同层次。

## 输入预处理到底在补什么

Claude Code 的输入不是“用户一输，模型就收”。

`processUserInput.ts` 这层至少会处理：

- slash command 识别
- prompt 类型判定
- hooks 触发
- 附件与 meta message 注入
- 输入规范化

这说明真正进入主循环前，系统已经先做了一轮编排。

## 工具调度到底在补什么

`toolOrchestration.ts` 的价值在于，它把“多个 tool call 怎么跑”从主循环里拆了出来。

这里最值得记住的是：

- 有些工具可以并发
- 有些工具必须串行
- 读类与写类工具的调度策略可能不同

这不只是性能优化，也是安全和一致性设计。

## 单次工具执行到底在补什么

`toolExecution.ts` 更像单次工具调用的统一包装器。

它负责把一次 tool use 收束成一条稳定执行链，例如：

- 输入校验
- 权限检查
- hooks
- telemetry
- progress
- 结果归一化

所以“调度多个工具”和“执行单个工具”并不是一层问题。

## 权限插入点为什么值得单独看

`useCanUseTool.tsx` 和 `utils/permissions/` 说明，权限不是执行阶段临时加的一句 if。

它已经是一条明确的运行时管线，会涉及：

- 静态规则
- permission mode
- classifier
- interactive approval
- worker / coordinator 特殊处理

更准确地说，Claude Code 的权限系统是嵌在工具执行链中的统一决策层。

## 一个具体场景怎么理解这几层

如果用户发来一条带附件的复杂请求，系统可能会先：

1. 在输入预处理层识别 slash command、附件和 meta message
2. 在工具调度层决定多个工具该并发还是串行
3. 在单次执行层逐个工具做校验、执行和结果包装
4. 在权限层对高风险工具插入审批或拒绝

这个场景能帮助我记住：这些中间层虽然连续出现，但各自解决的是不同问题。

## 易错点

- 容易把输入处理理解成“发给模型前做一点清洗”
- 容易把 tool orchestration 和 tool execution 混成一层
- 容易把权限系统理解成工具里的零散判断，而不是统一决策管线

- 容易只看到文件拆分，而忽略真正有价值的是把输入、调度、执行、权限这些横切复杂度放进稳定层次，让主循环专注在任务推进

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 会话、状态与上下文系统]]
- [[../../../20-主题/Agentic CLI/工具调用系统]]
- [[../../../20-主题/Agentic CLI/权限与安全边界]]
