---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Advisor
  - Suggestions
type: area
---

# Claude Code 建议系统与 Advisor 机制

## 研究边界

这篇只关注 `Claude Code` 如何给用户提供建议、提示和引导，不展开成通用推荐系统理论。

## 为什么这块重要

一个复杂 agent 产品即使能力很强，也可能有两个问题：

- 用户不知道下一步该怎么用
- 用户不知道哪些能力当前可用

所以“建议系统”不是锦上添花，而是把复杂能力变得可用的重要层。

## 我看到的相关线索

从源码命名和入口组织上，Claude Code 里明显有几类“建议型能力”：

- advisor 相关逻辑
- prompt suggestion
- tips / example commands
- command suggestions
- skill usage tracking / skill 提示

这说明它不是纯靠文档引导，而是在运行中动态帮助用户。

## Advisor 的角色

我当前把 advisor 理解成一种“轻量引导层”。

它的目标不是替代主代理，而是帮助用户：

- 更快进入正确操作路径
- 发现适合当前场景的命令或能力
- 降低复杂系统的上手门槛

这种机制对于具备大量命令、工具、插件、skills 的系统尤其重要。

## 为什么值得研究

Claude Code 里很多复杂度都来自“能力太多”：

- slash commands 很多
- tools 很多
- 插件和 skills 会继续扩展
- 不同模式下能力还会变化

如果没有建议层，用户面对的是一整套强能力黑盒。

## 我提炼出的实现启发

- 建议系统应贴近当前上下文，而不是只给静态帮助文档
- 复杂 agent 的引导能力本身就是产品能力
- advisor 最适合做“降低摩擦”的事，而不是增加新认知负担
- suggestions 最好和设置、权限、可用工具状态联动

## 我的理解

Claude Code 越像产品，就越不会假设用户会自己摸透所有能力。
建议系统的存在，本质上是在帮用户跨过复杂度门槛。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 命令系统与命令发现]]
- [[Claude Code REPL、Ink 与交互层]]
- [[Claude Code Hooks、Telemetry 与产品化观测]]
