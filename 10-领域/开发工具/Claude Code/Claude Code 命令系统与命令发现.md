---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 命令系统
  - Slash Command
type: area
---

# Claude Code 命令系统与命令发现

## 研究边界

这篇只讨论 `Claude Code` 的命令系统，不展开成通用 CLI 命令设计理论。

## 我研究这部分时最关心什么

- 命令来源有哪些
- 命令是静态注册还是动态发现
- 命令系统和工具系统如何分层
- 扩展能力如何进入用户可见入口

## 关键文件

- `src/commands.ts`
- `src/commands/`
- `src/skills/loadSkillsDir.ts`
- `src/utils/plugins/loadPluginCommands.ts`

## 我看到的核心结构

Claude Code 的命令系统不是一张静态表，而是“内建命令 + 动态发现命令”的混合模型。

从 `commands.ts` 可以看出，命令来源至少有几类：

- builtin commands
- bundled skills
- skills 目录里的命令/技能
- plugin commands
- plugin skills
- workflow commands

这意味着 `/命令` 不是手写死的，而是一个聚合结果。

## 命令和工具的关系

Claude Code 里有一个很重要的区分：

- `commands` 面向用户
- `tools` 面向模型

命令系统负责的是“人如何显式触发能力”，工具系统负责的是“模型如何在回合中调用能力”。

这两条线会互相连接，但不混成一层。

## 为什么命令发现机制重要

如果没有命令发现机制，扩展系统再强，用户也很难真正用起来。

Claude Code 的做法给我的启发是：

- 把命令注册中心单独做厚
- 允许技能和插件进入命令表
- 用统一 `Command` 抽象承接不同来源
- 按环境、feature flag、配置决定哪些命令可见

## 我提炼出的设计点

- 命令不仅是“调用某函数”，也是一种能力暴露协议
- 动态命令发现是平台化的前提
- 命令系统越开放，越需要和设置、权限、插件状态联动
- 命令聚合层适合成为“扩展系统对用户的可见界面”

## 如果继续往下读

我会优先追这几个问题：

1. 内建命令如何注册
2. skills 和 plugins 如何把命令注入注册表
3. 命令可见性如何受设置和环境影响
4. 命令执行最终如何回到主循环或工具层

## 我的理解

Claude Code 的命令系统，本质上是在做一件事：
把分散在源码、技能、插件里的能力，统一折叠成用户可操作的入口面。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[../../../20-主题/Agentic CLI/Agentic CLI 研究路线]]
