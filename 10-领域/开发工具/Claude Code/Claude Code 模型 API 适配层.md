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

## 这是什么

这篇笔记记录 Claude Code 怎样把内部运行时抽象翻译成真正的模型 API 请求。

这里的重点不是“怎么调用模型”，而是“内部 agent 运行时和外部模型接口之间怎样做翻译与收口”。

## 为什么重要

- Claude Code 的主循环、工具系统和权限系统并不会直接一一映射到模型 API
- 如果没有专门适配层，模型差异、streaming、成本统计和结构化输出会反向污染主循环
- 理解这层后，更容易看清主循环为什么能保持相对聚焦

## 关键入口

- `src/services/api/claude.ts`
- `src/services/api/errors.ts`
- `src/services/api/logging.ts`
- `src/cost-tracker.ts`

这些入口说明模型调用在 Claude Code 里不是一个薄函数，而是一整层服务。

## 这层主要在翻译什么

从职责上看，它至少在处理：

- model 选择与能力差异
- tool schema 转换
- thinking 配置
- structured output 配置
- task budget
- prompt caching
- streaming
- usage / token / cost 统计

更准确地说，这层是在把 Claude Code 的内部运行时对象翻译成一次可执行的模型请求，再把模型返回结果翻译回产品内部能消费的结构。

## 为什么这层不能散落在主循环里

如果把这些逻辑直接塞进主循环，就会很快混进下面这些问题：

- 哪个模型支持什么能力
- 哪些字段该怎么传
- streaming 事件怎样解释
- 用量和成本怎样归档
- 出错时是否应该重试或分类处理

Claude Code 把这些复杂度压进服务层之后，主循环就更容易专注在 agent 编排本身。

## 一个具体场景怎么理解这层

假设同一条内部任务需要：

- 带工具 schema
- 开启 thinking
- 接收 streaming 输出
- 记录 token 和成本

对主循环来说，这应该仍然只是“一次模型调用”。但对底层 API 来说，可能已经涉及多种字段翻译、能力判断和事件转换。

这个场景说明，模型 API 在成熟产品里更像“外部协议层”，不是透明黑盒。

## 这里最值得记住的点

- 模型能力差异适合在适配层统一收口
- streaming 和 cost 不是附带信息，而是运行时的一部分
- tool schema、thinking、结构化输出这些配置都适合在这里统一翻译

## 易错点

- 容易把模型 API 调用理解成主循环里的一个小步骤
- 容易把能力差异散落到业务逻辑里，而不是交给适配层统一处理
- 容易忽略 streaming、usage 和 errors，实际它们都会深度影响运行时行为

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
