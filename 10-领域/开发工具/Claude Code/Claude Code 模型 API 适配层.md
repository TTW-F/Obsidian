---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - API
  - Model Runtime
type: area
---

# Claude Code 模型 API 适配层

## 研究边界

这篇只关注 `Claude Code` 如何把自身 runtime 接到模型 API 上，不展开成通用 LLM API 教程。

## 我研究这部分时最关心什么

- 内部运行时抽象如何翻译成 API 请求
- 模型能力差异在哪里被收口
- streaming、预算、thinking、cost 由哪层负责
- 为什么主循环不应直接理解底层 API 细节

## 关键文件

- `src/services/api/claude.ts`
- `src/services/api/errors.ts`
- `src/services/api/logging.ts`
- `src/cost-tracker.ts`

## 我看到的定位

`services/api/claude.ts` 不是简单的“调一下 SDK”。

它更像模型侧运行时适配层，负责把 Claude Code 的内部抽象翻译成一次可执行的模型请求。

## 这层在做什么

从职责上看，它至少在处理：

- model 选择与能力差异
- tool schema 转换
- thinking 配置
- structured output 配置
- task budget
- prompt caching
- streaming
- usage / token / cost 统计

这说明 Claude Code 内部的 agent runtime 和外部模型 API 之间，并不是直接一一映射的。

## 为什么这一层重要

如果没有专门的 API 适配层，很多复杂度会反向污染主循环：

- 哪个模型支持什么能力
- 哪些字段怎么传
- streaming 事件怎么解释
- 用量和成本怎么记录
- 出错时如何分类重试

Claude Code 把这些逻辑压进服务层，主循环就能更专注于 agent 编排。

## 我提炼出的实现启发

- agent runtime 和模型 API 之间最好隔一层适配器
- “支持哪些模型”不该散落在业务逻辑里
- thinking、预算、结构化输出、tool schema 这些能力都适合在这层统一收口
- 用量与成本统计最好贴近 API 层，而不是事后补算

## 如果继续往下读

我会继续追：

1. API 适配层和 QueryEngine 的边界
2. 模型能力矩阵如何影响工具调用能力
3. streaming 事件怎样被转换成 UI / 状态更新
4. 错误分类和重试策略是不是也在这层完成

## 我的理解

真正成熟的 agent 产品，不会把模型 API 当成一个透明黑盒。
它会围绕 API 建一层自己的运行时翻译器。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 会话、状态与上下文系统]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
