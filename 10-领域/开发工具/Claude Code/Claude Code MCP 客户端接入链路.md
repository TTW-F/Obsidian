---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - MCP
  - Client
type: area
---

# Claude Code MCP 客户端接入链路

## 研究边界

这篇只关注 `Claude Code` 如何把 MCP server 接进自身运行时，不展开成通用 MCP 教程。

## 我研究这部分时最关心什么

- MCP 在系统里只是工具来源，还是正式能力总线
- 配置解析、连接管理、能力发现是否分层
- tools、resources、prompts、auth 如何一起进入运行时
- 外部 server 接入后怎样继续受本地治理

## 关键文件

- `src/services/mcp/client.ts`
- `src/services/mcp/config.ts`
- `src/services/mcp/types.ts`
- `src/tools/ListMcpResourcesTool/`
- `src/tools/ReadMcpResourceTool/`

## 为什么这块重要

MCP 在 Claude Code 里不是“附加功能”，而是外部能力总线之一。

它的价值不只是让模型多几个工具，而是把外部系统的：

- tools
- resources
- prompts
- auth
- elicitation

一起纳入 Claude Code 的运行时。

## 我看到的接入链路

我当前理解的链路大致是：

1. 先读取和解析 MCP 配置
2. 决定哪些 server 可以启用
3. 建立对应 transport 连接
4. 拉取 tools / resources / prompts
5. 把可见能力注入 Claude Code 的工具与上下文体系
6. 在运行中继续处理 auth、elicitation、连接缓存和资源刷新

这说明 MCP 接入不是单次初始化，而是一条持续参与会话运行的链路。

## Claude Code 为什么值得研究

因为它没有把 MCP 只做成一个“远程工具代理”。

相反，它在认真处理：

- stdio / SSE / HTTP / WebSocket 等 transport
- server 配置与策略过滤
- tool naming 与命令排除
- 资源读取与资源可见性
- 用户授权与交互式补全

这说明它是在把 MCP 当成平台接口，而不是脚本接口。

## 我提炼出的实现启发

- MCP 接入最好有独立客户端层，不要散落在工具实现里
- 配置解析、连接管理、能力发现、交互授权应该分层
- 外部 server 进入系统后，仍然要受本地权限与策略治理
- resources 和 prompts 与 tools 一样重要，不能只盯着 tool call

## 如果继续往下读

我会继续看：

1. MCP server 生命周期由谁管理
2. resources / prompts 如何进入上下文构建
3. auth 和 elicitation 是否会回流到主交互层
4. 本地权限系统如何覆盖外部 MCP 能力

## 我的理解

Claude Code 对 MCP 的处理方式说明，一个成熟 agent 平台不会只把外部协议当成“连上就行”，而会把它视为正式的能力接入面。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[../../../20-主题/Agentic CLI/技能、插件与扩展机制]]
