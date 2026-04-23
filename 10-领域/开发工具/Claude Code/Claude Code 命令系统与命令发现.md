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

## 这是什么

这篇笔记记录 Claude Code 怎样组织 slash command，以及这些命令怎样从内建能力、skills、plugins 等来源进入统一入口。

这里真正要理解的，不只是“有哪些命令”，而是“命令怎样成为用户可见的能力入口”。

## 为什么重要

- 一个可扩展的 agent 产品不能只靠固定命令表
- 命令系统既影响上手体验，也影响扩展能力是否真的能被用户发现
- 如果命令发现机制不清楚，再强的 skill 和 plugin 也会变成隐藏能力

## 关键入口

- `src/commands.ts`
- `src/commands/`
- `src/skills/loadSkillsDir.ts`
- `src/utils/plugins/loadPluginCommands.ts`

这些位置至少说明一件事：Claude Code 的命令系统不是静态注册表，而是一个聚合层。

## 命令来源大致分成哪几类

从 `commands.ts` 及相关加载逻辑看，命令来源至少包括：

- builtin commands
- bundled skills
- skills 目录里的命令或技能入口
- plugin commands
- plugin skills
- workflow commands

这说明 `/命令` 并不是手写死的，而是多来源汇总后的结果。

## 为什么命令和工具不能混成一层

Claude Code 里有一个很关键的区分：

- `commands` 面向用户，是显式入口
- `tools` 面向模型，是回合内可调用能力

这两层会相互连接，但解决的问题不同。

例如，一个命令可能让用户显式触发某种流程，而工具更像模型在执行中调用的能力单元。把两者混在一起，用户入口和模型执行边界就会越来越乱。

## 命令发现机制真正补的是什么

如果没有命令发现机制，扩展系统再强，用户也很难知道当前环境里到底有哪些入口能用。

Claude Code 这套做法给我的启发是：

- 把命令注册中心单独做厚
- 允许 skills 和 plugins 进入统一命令表
- 用统一 `Command` 抽象承接不同来源
- 按环境、feature flag、配置决定命令可见性

## 一个具体场景怎么理解这层

假设用户安装了一个新 plugin，又在本地 skills 目录里放进几条自定义能力。

如果命令系统足够成熟，用户不必手动记住所有分散入口，而是能通过统一命令表看到：

- 哪些命令当前可用
- 哪些来自内建系统
- 哪些来自 skill 或 plugin
- 哪些受环境、设置或 feature flag 影响而隐藏

这个场景能帮助我记住：命令系统不只是调用函数，而是在做能力暴露协议。

## 易错点

- 容易把命令系统和工具系统混成一层
- 容易把命令表看成静态注册表，忽略 skills、plugins、workflows 的动态注入
- 容易只关心“有没有命令”，不关心命令在当前环境里是否真的可见、可用
- 容易低估命令发现的重要性。对可扩展 agent 平台来说，能否把分散能力折叠成统一入口，和扩展机制本身一样关键

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 启动链路与运行模式]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code 建议系统与 Advisor 机制]]
- [[Claude Code REPL、Ink 与交互层]]
