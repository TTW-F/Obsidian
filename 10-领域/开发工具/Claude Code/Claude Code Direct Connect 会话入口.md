---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Direct Connect
  - 会话
  - Server
type: area
---

# Claude Code Direct Connect 会话入口

## 这是什么

这篇笔记整理的是 `src/server/` 这层真正负责的事情。

我现在更倾向于把它理解成“direct connect 会话入口”，而不是通用后端框架。它主要解决的是：如何向远端 server 创建一个 Claude 会话，再通过 WebSocket 持续收发 SDK 消息。

## 为什么重要

- `src/server/` 文件很少，但位置很关键
- 它把本地 REPL / headless 使用方式，延伸到了一个远端会话模型
- 这一层不是自己执行 agent，而是负责把远端会话接进现有 SDK message 协议

## 这层的三块核心文件

- `createDirectConnectSession.ts`
  - 负责向远端 server 申请创建 session
- `directConnectManager.ts`
  - 负责后续 WebSocket 生命周期和双向消息桥接
- `types.ts`
  - 负责 direct connect 响应和 session 元数据类型

这说明 `src/server/` 的重点不是业务逻辑，而是“会话建立 + 通信契约”。

## 一条最值得记住的主线

我现在会先把这条线记成：

1. 先 POST 到 `${serverUrl}/sessions`
2. 服务端返回 `session_id`、`ws_url`，可能还带 `work_dir`
3. 本地构造 `DirectConnectConfig`
4. `DirectConnectSessionManager` 用 `ws_url` 建 WebSocket
5. 双方通过与 `StructuredIO` 兼容的消息格式持续通信

这条线说明 direct connect 的本质是“远端会话接入 SDK 协议”，而不是简单 HTTP RPC。

## `createDirectConnectSession()` 的职责很克制

从 `createDirectConnectSession.ts` 看，这个函数只做三件事：

- 用 `fetch` POST `/sessions`
- 校验返回是否符合 `connectResponseSchema`
- 产出一个可直接给 REPL 或 headless runner 用的 `DirectConnectConfig`

这里最值得记住的是它传的参数：

- `cwd`
- `dangerously_skip_permissions`
- 可选 `Authorization` header

也就是说，会话创建阶段就已经在决定远端工作目录和权限模式。

## `DirectConnectSessionManager` 才是核心

真正持续工作的部分在 `directConnectManager.ts`。

我现在看到它至少承担了五层职责：

- 建立 WebSocket 连接
- 解析每一行 NDJSON / JSON 消息
- 区分 `control_request` 和普通 SDK message
- 把 permission request 变成回调
- 支持发用户消息、发中断、回权限响应

所以它更像一个“直接连接版的 RemoteIO/StructuredIO 适配器”，只是这次协议终点换成了 direct-connect server。

## 它为什么像 `StructuredIO` 的远端变体

从消息类型处理看，它已经在做一层协议筛选：

- `control_request`
  - 特别处理 `can_use_tool`
- `control_response`
  - 本地一般不转发给 UI
- `keep_alive`
  - 过滤掉
- `system post_turn_summary`
  - 过滤掉
- 普通 assistant / result / system message
  - 转发到上层

这说明 direct connect 并不是“原样把 WS 内容扔给 UI”，而是在保持 SDK 协议兼容的前提下做本地过滤与桥接。

## 权限交互是这层最关键的价值之一

`DirectConnectSessionManager` 对 `control_request.can_use_tool` 的处理很重要。

它的语义大致是：

- 远端 server 发来工具权限请求
- 本地 UI 收到 `onPermissionRequest`
- 用户允许或拒绝后，再通过 `control_response` 回传

换句话说，工具执行实际可能发生在远端，但权限决策仍然可以在本地交互面完成。

这也是 direct connect 相比“纯远端跑完给结果”的最大差异之一。

## `useDirectConnect()` 说明它怎么接进 REPL

从 `useDirectConnect.ts` 看，这层已经不是孤立能力，而是被正式挂进 REPL 的 remote mode。

我现在看到的接入方式很清楚：

- hook 持有 `DirectConnectSessionManager`
- 收到 SDK message 后，走 `convertSDKMessage()`
- 收到权限请求后，构造 synthetic assistant message 和 tool confirm queue
- 断连时会触发 `gracefulShutdown`
- `sendMessage()`、`cancelRequest()`、`disconnect()` 都统一成和其他 remote 模式相近的接口

这说明 direct connect 不是单独一套 UI，而是被抽象成与 SSH remote / remote session 同级的“远程交互后端”。

## `types.ts` 透露的会话心智模型

`types.ts` 里最有价值的不是 schema 本身，而是这些字段：

- `session_id`
- `ws_url`
- `work_dir`

以及更完整的 server/session metadata：

- `SessionState`
  - `starting / running / detached / stopping / stopped`
- `SessionIndexEntry`
  - 持久化稳定 session key、transcript session id、cwd、lastActiveAt

这说明 direct connect 背后默认的不是“一次性临时 socket”，而是一种可 detached、可恢复、可索引的会话模型。

## 这层和其他远端能力怎么分工

- [[Claude Code Bridge、Remote 与 IDE 集成]]
  - 更偏产品形态和集成面
- [[Claude Code CLI Structured IO 与 Remote Transport]]
  - 更偏 CLI / SDK 模式下的结构化协议与 transport
- 这篇
  - 更偏 direct connect 这条单独的会话创建与 WebSocket 消息桥

## 易错点

- 容易把 `src/server/` 当成完整后端实现，其实这里只看到 direct connect 客户端侧入口
- 容易把它理解成普通 websocket 聊天层，实际上它承载的是 SDK message / control request 协议
- 容易忽略权限请求是双向往返的，而不是纯本地判定
- 容易把 `createDirectConnectSession()` 当主逻辑，实际上它只是 session 建立前半步

## 我现在最想继续确认的点

- `bootstrap/state.ts` 里 direct connect config 是怎样注入启动链的
- `SessionIndexEntry` 真正持久化和恢复逻辑落在哪些文件
- direct connect server 端和 `RemoteSessionManager` 的关系是否共享同一套远端会话基础设施

## 相关笔记

- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code CLI Structured IO 与 Remote Transport]]
- [[Claude Code REPL、Ink 与交互层]]
- [[../../40-源码镜像/AI_Writer Vendor/Claude Code 目录到笔记映射]]
