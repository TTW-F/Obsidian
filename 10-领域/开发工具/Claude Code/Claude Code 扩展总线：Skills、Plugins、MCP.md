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

## 研究边界

这篇只写 `Claude Code` 里已经落地的扩展体系，重点看它如何把外部能力纳入同一套运行时。

## 我看到的三条扩展线

### 1. Skills

关键文件：

- `src/skills/loadSkillsDir.ts`
- `src/skills/bundled/index.ts`

Claude Code 的 skill 不是单纯提示词片段，而是带 frontmatter 的 Markdown 配置单元。

它能声明：

- 描述
- 何时使用
- allowed tools
- arguments
- model / effort
- hooks
- shell frontmatter

这意味着 skill 已经是一种轻量级能力包。

### 2. Plugins

关键文件：

- `src/utils/plugins/pluginLoader.ts`
- `src/utils/plugins/loadPluginCommands.ts`

插件系统负责的远不只是“加载一个目录”：

- 发现插件
- 校验 manifest
- 处理缓存与版本目录
- 装载 commands / agents / hooks / skills 风格内容
- 连接 marketplace / 官方源

这条线更接近正式生态能力。

### 3. MCP

关键文件：

- `src/services/mcp/client.ts`
- `src/services/mcp/config.ts`

MCP 在 Claude Code 里已经不是附属功能，而是外部集成总线之一。

它不仅接工具，还接：

- resources
- prompts
- auth
- elicitation
- 多种 transport

## 这三条线的关系

我现在的理解是：

- Skills：最低门槛，适合沉淀工作流和知识
- Plugins：正式扩展包，适合分发和生态管理
- MCP：外部系统接入协议，适合把 Claude Code 接到系统外部

三者不是互斥，而是分层协同。

## Claude Code 为什么值得研究

因为它没有把“扩展”做成三套各自为战的系统。

相反，它一直在尝试把这些扩展纳入统一框架：

- 统一命令发现
- 统一工具边界
- 统一权限治理
- 统一设置与策略约束

## 我提炼出的实现启发

- 扩展系统最难的不是“能不能加载”，而是“加载后能不能被治理”
- Markdown skill、插件包、协议型集成，最好不要混成同一种东西
- 扩展能力越强，越需要更强的权限和状态管理

## 我的理解

Claude Code 的平台化，不是因为它功能多，而是因为它给不同扩展形态都安排了位置。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code Agent 主循环与工具执行]]
- [[../../20-主题/Agentic CLI/技能、插件与扩展机制]]
