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

## 这是什么

这篇笔记记录 Claude Code 怎样把 MCP server 接进自己的运行时，以及这些外部能力怎样继续受本地系统治理。

这里的重点不是“怎么配置 MCP”，而是“外部协议怎样被接成平台能力”。

## 为什么重要

- MCP 在 Claude Code 里不是附加功能，而是正式的外部能力接入面
- 一旦外部 server 能提供 tools、resources、prompts 和 auth，系统就必须回答接入、可见性和治理问题
- 理解这条接入链路，有助于判断 Claude Code 为什么能把外部能力纳入同一套运行时

## 关键源码入口

- `src/services/mcp/client.ts`
- `src/services/mcp/config.ts`
- `src/services/mcp/types.ts`
- `src/tools/ListMcpResourcesTool/`
- `src/tools/ReadMcpResourceTool/`

这些位置至少说明两件事：

1. MCP 有独立的客户端和配置层
2. MCP 暴露出来的资源已经能进入工具体系，而不只是停在底层连接层

## Claude Code 的 MCP 接入链大致怎么走

可以先记成下面这条链：

1. 读取并解析 MCP 配置
2. 决定哪些 server 可以启用
3. 建立对应 transport 连接
4. 拉取 tools、resources、prompts 等能力
5. 把这些能力注入 Claude Code 的工具与上下文体系
6. 在运行过程中继续处理 auth、elicitation、连接缓存和资源刷新

这说明 MCP 接入不是一次性初始化，而是一条持续参与会话运行的链路。

## 这里最值得记住的几个点

### transport 不止一种

从客户端和配置层可以看出，这里要处理的不只是一个固定连接方式，而是可能覆盖 stdio、SSE、HTTP、WebSocket 等 transport。

### MCP 不只是工具来源

对 Claude Code 来说，MCP 带进来的不仅是 tools，还有：

- resources
- prompts
- auth
- elicitation

这点很重要，因为它说明 MCP 在这里更像平台接口，而不是远程工具代理。

### 外部能力不会脱离本地治理

即使能力来自外部 server，它仍然需要进入本地权限、策略和可见性规则的约束范围。

## 一个具体场景怎么理解这条链路

如果某个 MCP server 提供一组资源读取能力和几个工具，那么 Claude Code 不能只“把工具列出来”就结束了，它还得继续回答：

- 这些能力是否对当前会话可见
- 需要什么授权
- 资源是否能进入上下文
- 出错或断连后怎样恢复

这正是 MCP 接入链比“调用远程 API”复杂的地方。

## 易错点

- 容易把 MCP 只理解成工具来源，忽略 resources、prompts、auth 和 elicitation
- 容易把 MCP 接入看成一次性初始化，忽略连接、授权和资源刷新会持续参与运行时
- 容易假设外部能力接进来后就脱离本地治理，但在 Claude Code 里它们仍然会继续碰到本地权限、可见性和资源管理逻辑

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[../../../20-主题/Agentic CLI/技能、插件与扩展机制]]
