---
tags:
  - 主题
  - OpenAI Agents SDK
  - MCP
  - Transport
  - Session
type: topic
---

# OpenAI Agents SDK MCP Transport 与 Session 建立

## 这是什么

这篇笔记专门整理 `src/agents/mcp/server.py` 里 transport 与 session 建立的这一层。

如果上一篇 `MCP 连接管理与调用链` 更像管理面，这篇就是把底层连接面继续压实。

## 为什么重要

- `MCPServerManager` 解决的是 server 生命周期
- 真正每个 server 怎样把 transport 接进 `ClientSession`，是在 `server.py`
- 这里决定了 `stdio / SSE / streamable HTTP` 三类接法在初始化、超时、清理和失败恢复上的差异

## 一条总的建立流程

从 `_MCPServerWithClientSession.connect()` 看，三种 transport 最终都会收敛到同一条主线：

1. `create_streams()` 先创建 transport 对应的读写流
2. 从 transport 解出 `read / write`
3. 如果 transport 额外提供 session-id 回调，也会在这里捕获
4. 用 `read / write` 构造 `ClientSession`
5. 调用 `session.initialize()`
6. 成功后把 session 挂到 server 上

所以 transport 的差异主要发生在“怎样拿到 streams”这一步，而不是 session 主体逻辑完全分叉。

## `_MCPServerWithClientSession.connect()` 的几个关键点

这段连接代码里我现在最想记住三件事：

- `streamablehttp_client` 返回三元组：`read / write / get_session_id`
- `sse_client` 返回二元组：`read / write`
- 一旦连接失败，`finally` 里会尝试 cleanup，避免半连状态残留

此外它还做了 HTTP 错误抽取和包装：

- `ConnectError`
- `TimeoutException`
- `HTTPStatusError`

这意味着 SDK 已经把“transport 建连失败”显式转成了更可读的用户错误，而不是原样把底层异常漏出去。

## `stdio` 是最薄的一层

`MCPServerStdio.create_streams()` 基本就是：

- 把参数整理成 `StdioServerParameters`
- 直接调用 `stdio_client(self.params)`

它最适合本地子进程型 MCP server。

从测试 `test_connect_disconnect.py` 看，`stdio` 这条线的重点是：

- 支持 `async with server`
- 也支持手动 `connect()` / `cleanup()`
- 连接后 `session` 存在，清理后 `session` 清空

也就是说，`stdio` 这一支最“朴素”，主要靠统一 session 管理吃到上层能力。

## `SSE` 比 `stdio` 多了 HTTP client 配置面

`MCPServerSse.create_streams()` 会把这些参数交给 `sse_client()`：

- `url`
- `headers`
- `timeout`
- `sse_read_timeout`
- `auth`
- `httpx_client_factory`

这说明 SSE 这一支虽然仍然简单，但已经进入“HTTP transport 可定制”的世界。

测试也说明 `httpx_client_factory` 是正式扩展点，不是内部 hack。它可以让调用方注入：

- 自定义 SSL 证书
- proxy
- 特定 timeout
- 自定义 auth 处理

## `streamable HTTP` 是最复杂的一支

`MCPServerStreamableHttp` 明显比 `stdio` 和 `sse` 重。

我现在看到它多出来的能力至少有四个：

### 1. session-id 暴露

这一支的 transport 会返回 `get_session_id` 回调，server 会把它保存为 `_get_session_id`。

测试已经确认：

- connect 前 `session_id` 是 `None`
- connect 后会从回调里动态读取
- cleanup 后 `_get_session_id` 会清空，`session_id` 重新变成 `None`

这意味着 streamable HTTP 不只是“能连”，还支持把底层会话标识暴露出来，便于恢复或续接语义。

### 2. 初始化通知容错

`ignore_initialized_notification_failure=True` 时，它不会直接走默认 `streamablehttp_client()`，而会走 `_streamablehttp_client_with_transport(...)`，并用 `_InitializedNotificationTolerantStreamableHTTPTransport` 包起来。

这个分支的意思很清楚：

- `notifications/initialized` 属于 best-effort
- 如果这一步 POST 失败，可以选择只记日志、不让整条 transport 直接报废

这说明作者已经遇到过“初始化通知失败，但后续请求仍可能继续成功”的真实场景。

### 3. isolated session retry

这一支最有意思的不是建连，而是 call_tool 时的恢复策略。

从 `_call_tool_with_shared_session()`、`_call_tool_with_isolated_retry()` 看：

- 默认优先走共享 session
- 如果碰到特定异常，会判定“这次请求应该切到 isolated session 重试”
- isolated retry 会临时新建一个 session，单独完成这次工具调用，再清掉

触发 isolated retry 的异常包括：

- `CancelledError`
- `ClosedResourceError`
- `ConnectError`
- `TimeoutException`
- 5xx HTTPStatusError
- 某些 `McpError`

所以 streamable HTTP 这条线不是简单“连一次一直用”，而是允许在共享会话不稳定时，把单次请求隔离出来补救。

### 4. 请求串行化

`MCPServerStreamableHttp` 里还会设置 `_serialize_session_requests = True`。

我现在更倾向于把这个理解成：

- 共享 session 的请求并发性更敏感
- 需要在 server 层主动把同一会话上的请求顺序压住

这和 `HybridTransport` 那种“为了避免冲突而串行化写入”的思路是很像的。

## 三种 transport 的差异怎么记

我现在会这样压缩：

- `stdio`
  - 最薄，子进程本地通信
- `SSE`
  - HTTP/SSE 长读流，增加 auth 和 httpx client 配置面
- `streamable HTTP`
  - 最完整，除了 HTTP transport 本身，还多出 session-id、初始化容错、共享会话失败后 isolated retry

所以如果只是从产品复杂度看，`streamable HTTP` 明显是最“面向长期连接与恢复”的 transport。

## 测试暴露出的稳定语义

### connect / cleanup 语义

`test_connect_disconnect.py` 说明：

- async context manager 是一等用法
- 手动 connect / cleanup 也保持相同状态转换
- `session` 是否为空就是是否已初始化的关键标记

### client factory 语义

`test_streamable_http_client_factory.py` 说明：

- `httpx_client_factory` 是公开参数
- 默认不传时，不会多塞无关参数
- 传入后会原样进入 `streamablehttp_client()`

所以 transport 配置层已经明确支持调用方自定义底层 HTTP client。

### session-id 语义

`test_streamable_http_session_id.py` 说明：

- 只有 streamable HTTP 暴露 session-id
- session-id 由 transport 回调驱动，不是 server 自己缓存一个静态值
- cleanup 后必须清掉它，避免外部误以为连接还活着

## 它和上一篇 MCP 笔记怎么分工

- [[OpenAI Agents SDK MCP 连接管理与调用链]]
  - 更偏 server manager、tool bridge、Runner 接入
- 这篇
  - 更偏每个 server 内部怎样建 session、怎样处理 transport 差异与失败恢复

## 易错点

- 容易把三种 transport 当成只是参数不同，实际上 streamable HTTP 的恢复语义明显更重
- 容易忽略 session-id 只在 streamable HTTP 这一支存在
- 容易只看到 connect 成功路径，忽略失败时 cleanup 也是连接流程的一部分
- 容易把 isolated retry 当成 manager 层逻辑，实际上它在 server transport 层

## 我现在最想继续确认的点

- `_maybe_serialize_request()` 具体怎样约束共享 session 并发
- message handler 在三种 transport 下是否有不同观测特征
- streamable HTTP 的 resume/续接能力在更高层是否已经被正式消费

## 相关笔记

- [[OpenAI Agents SDK MCP 连接管理与调用链]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
