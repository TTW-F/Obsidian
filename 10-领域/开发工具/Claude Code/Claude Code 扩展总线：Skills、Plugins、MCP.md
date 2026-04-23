---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Skills
  - Plugins
  - MCP
type: area
---

# Claude Code 扩展总线：Skills、Plugins、MCP

## 这是什么

这篇笔记记录 Claude Code 里三条最重要的扩展入口：Skills、Plugins、MCP。

它真正要说明的，不是“支持三种扩展”，而是这三条线分别解决什么问题，又怎样被放进同一套运行规则里。

## 为什么重要

- Claude Code 的复杂度很大一部分来自扩展能力
- 如果不把这三条线分清，Markdown skill、正式插件包和外部 MCP server 很容易被混成一类东西
- 扩展机制是否分层清楚，会直接影响平台能不能持续长大

## 三条扩展线各自更像在解决什么

### 1. Skills：最低门槛的轻量能力包

关键入口包括：

- `src/skills/loadSkillsDir.ts`
- `src/skills/bundled/index.ts`

Claude Code 的 skill 不是单纯提示词片段，而是带 frontmatter 的 Markdown 配置单元。

它可以声明：

- 描述
- 何时使用
- allowed tools
- arguments
- model / effort
- hooks
- shell frontmatter

这意味着 skill 更像轻量级能力包，适合沉淀工作流和知识。

### 2. Plugins：正式扩展包与生态能力

相关入口包括：

- `src/utils/plugins/pluginLoader.ts`
- `src/utils/plugins/loadPluginCommands.ts`

插件系统负责的远不只是“加载一个目录”，还会处理：

- 发现插件
- 校验 manifest
- 处理缓存与版本目录
- 装载 commands / agents / hooks / skills 风格内容
- 连接 marketplace / 官方源

这条线更接近正式生态能力。

### 3. MCP：外部系统接入协议

相关入口包括：

- `src/services/mcp/client.ts`
- `src/services/mcp/config.ts`

MCP 在 Claude Code 里已经不是附属功能，而是外部集成总线之一。

它带进来的不只是工具，还包括：

- resources
- prompts
- auth
- elicitation
- 多种 transport

## 可以先怎样区分三者

- Skills：通过 `loadSkillsDir.ts` 加载的轻量配置单元
- Plugins：通过 `pluginLoader.ts` 管理的正式扩展包
- MCP：通过 `services/mcp/client.ts` 接入的外部能力入口

三者不是互斥关系，而是分层协同。

## 为什么“扩展总线”这个说法成立

Claude Code 之所以像“扩展总线”，不是因为名字多，而是因为这些入口最后都会回接到同一批平台层，例如：

- `loadPluginCommands.ts` 这样的统一命令发现入口
- `tools.ts` 和相关工具边界
- 权限与设置系统
- 运行时里的策略约束

换句话说，它不是分别接了三套孤立系统，而是在源码里把这些扩展尽量收回同一批入口和治理点。

## 一个具体场景怎么理解这三条线

比如一个用户可能同时：

- 写一个本地 skill 来固定自己的工作流
- 安装一个 plugin 扩展命令和代理定义
- 接入一个 MCP server 提供外部资源和工具

如果平台设计得不清楚，这三类能力很快就会在可见性、权限和入口上互相打架。

在 Claude Code 里，这三条线最终都会继续碰到命令暴露、工具暴露和权限裁剪，而不是各自停在独立入口里。

## 易错点

- 容易把 skills、plugins、MCP 混成一种扩展机制
- 容易只盯着“加载能力”，忽略能力接进来后是否还能被权限、设置和命令系统统一治理
- 容易把 MCP 只理解成远程工具调用，而忽略 resources、prompts、auth 和 elicitation
- 容易只记住概念分类，而忽略具体回接点。对 Claude Code 来说，更关键的是这些扩展最后落到哪些加载器、命令入口和治理模块

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code MCP 客户端接入链路]]
- [[Claude Code 插件加载与 Marketplace 机制]]
- [[../../20-主题/Agentic CLI/技能、插件与扩展机制]]
