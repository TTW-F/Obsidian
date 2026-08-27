---
title: 项目导航 MOC
tags:
  - onboarding
  - moc
status: active
updated: 2026-08-27
---

# 项目导航 MOC · AI_Novels_OpenCode

> [!abstract] 这是你（实习生）的 onboarding 中枢
> 本 vault 把 `F:\AI_Novels_OpenCode`（OpenCode fork → 网文 SaaS）的知识整理成互链笔记。**从 [[01 项目是什么]] 开始**，按 [[04 必读文档路线]] 推进，每天对照 [[06 实习学习路线]]。

> [!tip] 完全零基础？先读 [[09 名词解释]]
> 里面用大白话+比喻解释了 monorepo、OpenCode、fork、HEAD、SSE、wikilink 等所有黑话。其他笔记里的生词都链到了它。

## 知识地图（Mermaid）

```mermaid
graph TD
    A[01 项目是什么] --> B[02 领域词汇表]
    A --> C[03 分层架构与包地图]
    C --> D[05 代码入口走读]
    A --> E[04 必读文档路线]
    E --> F[06 实习学习路线]
    G[07 机器拓扑与红线] --> F
    C -.桥接.-> H[(OpenCode 引擎)]
    GL[09 名词解释] --> A
```

## 笔记清单

### 核心概念
- [[09 名词解释]] — 🚨 零基础第一读：所有黑话的大白话词典
- [[01 项目是什么]] — 这项目到底是什么、设计铁律、分层
- [[02 领域词汇表]] — CONTEXT.md 的 ubiquitous language（写代码/文档/票据必须用）
- [[03 分层架构与包地图]] — 底座引擎 vs 领域层 vs 前端的包划分

### 怎么学 / 怎么干
- [[04 必读文档路线]] — 文档阅读顺序（含仓库内绝对路径）
- [[05 代码入口走读]] — 从哪个文件开始读源码
- [[06 实习学习路线]] — 5 天实习计划（带 checkbox）
- [[07 机器拓扑与红线]] — 开发机 vs 192.168.31.35，哪些事绝对不能做

## 使用约定
- 所有 `[[wikilink]]` 都能在 Obsidian 里点击跳转；改文件名 Obsidian 会自动更新链接。
- 仓库路径用反引号代码块标注（如 `packages/novel-server/src/main.ts`），方便回 IDE 对照。
- 红线性内容（机器拓扑、并发不变量）用 `> [!warning]` / `> [!danger]` callout 标出。
- 想加自己的笔记，复制一篇的 frontmatter 模板即可，记得加 `tags: [onboarding]`。
