---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - CLI
  - IO
  - Transport
type: area
---

# Claude Code CLI Structured IO 与 Remote Transport

## 这是什么

这篇笔记整理的是 `src/cli/` 这一层最值得先抓住的结构。

如果说 `QueryEngine` 决定 agent 怎样思考，那么 `cli/` 更像是在决定这些状态、事件和控制请求怎样被序列化、传出去、再收回来。

## 为什么重要

- Claude Code 不只是一个本地 TUI，它还要支持 SDK 模式、bridge、remote session
- 所以 CLI 层并不只是“打印文本”，而是承担一层协议边界
- 从 `structuredIO.ts`、`remoteIO.ts` 和 `transports/` 看，这里其实有一条很完整的消息管线

## 我现在看到的三层结构

### 1. `StructuredIO`

`structuredIO.ts` 是这层的中心。

我现在更倾向于把它理解成“stdio 上的 SDK 协议适配器”，而不是普通输入输出工具类。

它做的几件关键事包括：

- 把原始输入流解析成 `StdinMessage | SDKMessage`
- 维护 `pendingRequests`
- 跟踪已解决的 `tool_use_id`
- 维护 outbound queue，避免控制请求和 stream event 乱序
- 处理权限请求、control request、session state 通知

最关键的一点是：这里已经不是 UI 文本层，而是控制协议层。

### 2. `RemoteIO`

`remoteIO.ts` 说明 Claude Code 在 remote / bridge 模式下，不再只依赖本地 stdin/stdout。

我现在看到它主要承担：

- 根据 URL 选择 transport
- 注入 session token 等 header
- 把 transport 收到的数据写回 input stream
- 在 CCR v2 模式下接管 internal event 的写入和读取
- 维护 keep-alive，避免远程会话被中间层清掉

也就是说，`RemoteIO` 是把 `StructuredIO` 放到远程连接之上的桥接层。

### 3. `transports/`

`transports/` 这一层负责真正的网络收发策略。

从 `HybridTransport.ts` 看，它不是简单的 WebSocket client，而是显式区分了：

- 读：走 WebSocket
- 写：走 HTTP POST
- 高频 `stream_event`：先缓冲，再批量发送
- 写失败：交给序列化 uploader 重试

这里的重点是“顺序、批量、重试、背压”，说明 CLI remote transport 已经是产品化的数据通道，而不是临时拼的连接器。

## 一条最值得记住的消息链

我现在会先记成：

1. 输入先进入 `StructuredIO`
2. 如果是 remote 模式，由 `RemoteIO` 把它挂到 transport 上
3. transport 负责具体协议
4. 收到的数据重新灌回 input stream
5. 上层再把这些结构化消息交回 agent/session 主循环

所以 `cli/` 这一层真正解决的是“远程会话如何像本地会话一样被驱动”。

## 为什么 `StructuredIO` 值得单独记

从当前文件看，它处理的不只是消息读写，还包括：

- 权限控制请求
- hook 结果
- session state 变化
- tool use 去重
- outbound 顺序控制

这说明 Claude Code 的 SDK/CLI 模式，已经把“可交互 agent”抽象成了一套消息协议，而不是直接暴露内部状态。

## 为什么 `HybridTransport` 很有意思

`HybridTransport.ts` 暴露了一个很清楚的产品化判断：

- 读和写可以走不同通道
- 高频 stream event 不能每条都直接 POST
- fire-and-forget 写法会带来并发写冲突，所以要做串行批处理

这组设计明显不是为了“功能跑通”，而是为了在 bridge/remote 场景里把吞吐、重试和顺序问题压平。

## 目录里其他文件大致怎么理解

- `print.ts`
  - CLI 启动后把命令、工具、session、settings、remote 初始化都接起来，属于“CLI 入口编排层”
- `remoteIO.ts`
  - 远程会话与 StructuredIO 的桥接层
- `structuredIO.ts`
  - 协议解析与 control request 中心
- `ndjsonSafeStringify.ts`
  - 结构化输出的安全序列化辅助
- `handlers/`
  - auth、mcp、plugins、agents 等 CLI 子入口
- `transports/`
  - WebSocket / SSE / Hybrid / CCR 相关运输层

## 它和其他笔记怎么分工

- [[Claude Code REPL、Ink 与交互层]]
  - 更偏本地交互体验
- [[Claude Code Bridge、Remote 与 IDE 集成]]
  - 更偏产品集成与远程形态
- 这篇
  - 专门补 `src/cli/` 里的结构化协议、远程 IO 和 transport 层

## 易错点

- 容易把 `cli/` 当成纯输出层，实际上它已经是协议层
- 容易把 `RemoteIO` 当 transport，本质上它更像 StructuredIO 和 transport 之间的桥
- 容易只看 WebSocket，而忽略 `HybridTransport` 暴露出的批处理和可靠性设计

## 我现在最想继续确认的点

- `handlers/` 怎么把各类命令绑定到统一协议输出
- `SSETransport` 和 `WebSocketTransport` 在连接恢复策略上怎么分工
- `ccrClient.ts` 和 internal event persistence 的边界到底在哪

## 相关笔记

- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code REPL、Ink 与交互层]]
- [[Claude Code 命令系统与命令发现]]
- [[Claude Code Hooks、Telemetry 与产品化观测]]
- [[../../40-源码镜像/AI_Writer Vendor/Claude Code 目录到笔记映射]]
