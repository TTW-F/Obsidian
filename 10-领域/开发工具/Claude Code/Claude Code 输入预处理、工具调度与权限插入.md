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

## 研究边界

这篇聚焦 `Claude Code` 中几个很关键但容易被忽略的运行时插层：输入预处理、工具调度、权限插入。

## 关键文件

- `src/utils/processUserInput/processUserInput.ts`
- `src/services/tools/toolOrchestration.ts`
- `src/services/tools/toolExecution.ts`
- `src/hooks/useCanUseTool.tsx`
- `src/utils/permissions/`

## 输入预处理

Claude Code 的输入不是“用户一输，模型就收”。

`processUserInput.ts` 这层至少在做：

- slash command 识别
- prompt 类型判定
- hooks 触发
- 附件与 meta message 注入
- 输入规范化

这说明真正进入主循环之前，系统已经做了一轮编排。

## 工具调度

`toolOrchestration.ts` 的价值在于，它把“多个 tool call 怎么跑”从主循环里拆出来了。

我当前理解的重点是：

- 有些工具可以并发
- 有些工具必须串行
- 读类与写类工具的调度策略不同

这不是单纯性能优化，也是安全与一致性设计。

## 单次工具执行

`toolExecution.ts` 更像工具调用的统一包装器。

它负责把一次 tool use 规范化为一条稳定执行链：

- 输入校验
- 权限检查
- hooks
- telemetry
- progress
- 结果归一化

这说明工具真正执行前后，有很多“横切关注点”需要统一插入。

## 权限插入点

`useCanUseTool.tsx` 和 `utils/permissions/` 说明，权限不是执行阶段临时加的一句 if。

它已经是一条明确的运行时管线：

- 静态规则
- permission mode
- classifier
- interactive approval
- worker / coordinator 特殊处理

所以更准确地说，Claude Code 的权限系统是“嵌入在工具执行链中的统一决策层”。

## 为什么这部分重要

很多 agent 原型容易忽略这几层，最后变成：

- 输入路径混乱
- 工具执行耦合在主循环里
- 权限逻辑散落在各个工具内部

Claude Code 之所以像产品，不只是因为功能多，而是因为这些中间层被认真建出来了。

## 我的理解

真正让 agent 可维护的，不只是模型和工具，而是这些“看起来不像功能、但实际上决定系统形态”的中间层。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 会话、状态与上下文系统]]
- [[../../20-主题/Agentic CLI/工具调用系统]]
- [[../../20-主题/Agentic CLI/权限与安全边界]]
