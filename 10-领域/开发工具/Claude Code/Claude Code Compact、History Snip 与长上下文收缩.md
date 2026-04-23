---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Compact
  - Context Window
type: area
---

# Claude Code Compact、History Snip 与长上下文收缩

## 研究边界

这篇只关注 `Claude Code` 如何处理长会话里的上下文膨胀问题，不展开成通用 prompt compression 理论。

## 我研究这部分时最关心什么

- 长会话里什么东西会最先失控
- compact、history snip、replay 各自承担什么职责
- 历史收缩如何既省 token 又不断任务
- 上下文压缩是否已经被做成运行时机制

## 为什么这块重要

Claude Code 面向的是长任务、长会话、长生命周期。

一旦会话变长，系统就一定要面对几个问题：

- 上下文窗口会被吃满
- 历史消息会越来越贵
- 旧信息既不能全丢，也不能全带

所以“怎么压缩历史”不是优化项，而是 agent 产品的基础能力。

## 我看到的相关线索

从 `src/query.ts`、`src/QueryEngine.ts`、`src/services/compact/` 以及 feature flag 里能看出，Claude Code 在认真做：

- compact
- reactive compact
- history snip
- 投影式历史视图
- 长会话中的 replay / truncate

它不是简单删几条消息，而是在构建一套“能继续工作”的历史收缩机制。

## 我当前的理解

这套机制要解决的，不只是 token 数量，而是三个目标同时成立：

- 保住当前任务连续性
- 降低上下文成本
- 不让用户感觉系统突然失忆

这也是为什么 Claude Code 会把它做成独立服务层，而不是在主循环里随手截断数组。

## History Snip 给我的启发

从命名上看，`history snip` 不是普通 compact。

它更像是在做：

- 找到可裁切边界
- 保留关键结构信息
- 为长会话提供可投影、可回放的历史视图

这类设计很像“上下文内存管理”，而不是单纯摘要。

## 我提炼出的实现启发

- 长会话 agent 不能依赖“把完整历史一直带着”
- 历史收缩最好是运行时机制，而不是人工维护动作
- compact 与 replay 最好成对设计，否则压缩后很难继续稳定执行
- 上下文管理应该服务于任务连续性，而不只是节省 token

## 如果继续往下读

我会继续关注：

1. compact 触发条件由谁决定
2. snip / replay 如何和 session persistence 对齐
3. 历史压缩后哪些关键状态仍会被显式保留
4. 成本控制和用户体验之间如何平衡

## 我的理解

Claude Code 真正体现产品成熟度的一个点，就是它已经认真面对“长任务一定会压垮上下文”这个现实，并把解决方案做进了运行时。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 会话、状态与上下文系统]]
- [[Claude Code 模型 API 适配层]]
