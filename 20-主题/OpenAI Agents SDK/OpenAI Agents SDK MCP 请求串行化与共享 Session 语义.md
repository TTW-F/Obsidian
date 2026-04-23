---
tags:
  - 主题
  - OpenAI Agents SDK
  - MCP
  - Session
  - Streamable HTTP
type: topic
---

# OpenAI Agents SDK MCP 请求串行化与共享 Session 语义

## 这是什么

这篇笔记专门拆 `src/agents/mcp/server.py` 里 `_maybe_serialize_request()` 附近的语义。

如果上一页 `MCP Transport 与 Session 建立` 讲的是“怎么连上”，这一页更关心的是：连上以后，为什么有些请求必须在共享 session 上串行跑，以及 shared session 和 isolated session 到底怎么分工。

## 为什么重要

- `MCPServerStreamableHttp` 不是只比 `stdio` 和 `SSE` 多一个 HTTP transport，它还多了一套共享 session 保护语义
- `_maybe_serialize_request()` 虽然实现很短，但它约束的是整张 session 表面的并发方式，而不只是某个工具调用细节
- 如果不把这层看清，很容易误以为 isolated retry 只是“失败后再试一次”，而忽略了它其实是在切换 session 作用域

## `_maybe_serialize_request()` 真正在做什么

从 `server.py:559-563` 看，这个方法本体非常简单：

- 默认直接执行传入的请求函数
- 只有当 `self._serialize_session_requests = True` 时，才会套上一层 `self._request_lock`

也就是说，它不是序列化某种特定请求，而是在 server 层定义了一个开关：

- 这个 server 的共享 session 是否允许并发请求

我现在更愿意把它理解成“共享 session 的并发护栏”，而不是“某个方法的内部优化”。

## 它约束的是整张共享 session 表面

最容易忽略的一点是：这层串行化不只包 `call_tool()`。

从 `server.py` 可以看到，这些方法都会经过 `_maybe_serialize_request()`：

- `list_tools()`
- `call_tool()`
- `list_prompts()`
- `get_prompt()`
- `list_resources()`
- `list_resource_templates()`
- `read_resource()`

所以它约束的是“同一个共享 `ClientSession` 上的所有 MCP 请求”，而不是“tool 调用偶尔上个锁”。

## 为什么只有 streamable HTTP 默认打开串行化

`_MCPServerWithClientSession` 初始化时默认 `self._serialize_session_requests = False`，而 `MCPServerStreamableHttp.__init__()` 会明确把它改成 `True`。

这件事和 transport 差异是绑在一起的：

- `stdio`
  - 更像本地子进程通信，server 侧没有额外 session-id 和共享 HTTP 会话恢复语义
- `SSE`
  - 也走共享 `ClientSession`，但这层实现没有额外打开 SDK 侧请求串行化
- `streamable HTTP`
  - 明确把共享 session 当成更脆弱、也更值得保护的对象

所以这里不是“所有 transport 都该串行，只是作者漏了”，而是 SDK 明确认为 streamable HTTP 这一支需要更强的共享会话保护。

## shared session 和 isolated session 怎么分工

这条线从 `server.py:1451-1546` 看得最清楚。

### 先走 shared session

正常 `call_tool()` 会先进入 `_call_tool_with_shared_session()`：

- 直接拿当前 `self.session`
- 经 `_maybe_serialize_request()` 后调用 `_call_tool_with_session()`

所以默认路径仍然是“复用已经建立好的共享 session”。

### 某些失败会触发 isolated retry

如果共享 session 上的调用抛出特定异常，`_call_tool_with_shared_session()` 不会立即把原异常往上抛，而是转成 `_SharedSessionRequestNeedsIsolation`。

会触发这条支线的异常包括：

- `asyncio.CancelledError`
- `ClosedResourceError`
- `httpx.ConnectError`
- `httpx.TimeoutException`
- 5xx `HTTPStatusError`
- code 为 `408` 的 `McpError`
- 全部子异常都满足上述条件的 `BaseExceptionGroup`

这里最值得记住的是：SDK 并不是把这些异常都视为“工具本身失败”，而是把它们解释成“共享 session 可能已经不适合继续承接这次请求”。

### isolated retry 不是第二次 shared call

`_call_tool_with_isolated_retry()` 在捕获 `_SharedSessionRequestNeedsIsolation` 后，会临时新建 `_isolated_client_session()`：

- 新建 transport
- 新建 `ClientSession`
- 重新 `initialize()`
- 只执行这一次工具调用
- 用完立即清掉

所以 isolated retry 的本质不是“重试同一个连接”，而是“把这次请求挪到一个临时独立 session 上完成”。

## 请求串行化和 isolated retry 是互补关系

我现在会把它们记成两个层级：

- `_maybe_serialize_request()`
  - 解决共享 session 上的并发冲突
- isolated retry
  - 解决共享 session 已经不稳定时，单次请求怎么脱困

也就是说：

- 串行化是在尽量保护 shared session
- isolated retry 是 shared session 保护失败后的降级逃生口

这两层一起看，`streamable HTTP` 的设计意图才完整。

## 测试暴露出的真实语义

`tests/mcp/test_client_session_retries.py` 很能说明作者到底在防什么。

### 1. 串行化是为了避免 sibling cancellation

`test_serialized_session_requests_prevent_sibling_cancellation()` 和
`test_serialized_prompt_requests_prevent_tool_cancellation()` 说明：

- 如果共享 session 上两个请求并发跑
- 一个请求可能会把另一个还在进行中的 sibling request 取消掉

而开启序列化后：

- 慢请求可以正常返回
- 失败请求单独失败
- 不会把兄弟请求一起拖死

这说明 `_maybe_serialize_request()` 的目标不是“让顺序更好理解”，而是防止共享 session 上的并发请求互相伤害。

### 2. prompt 请求和 tool 请求也要互相串行

`test_streamable_http_serializes_call_tool_with_prompt_requests()` 进一步确认：

- `call_tool()` 和 `list_prompts()/get_prompt()` 之间也不能安全并发
- `shared_session.max_in_flight == 1`

这和上面源码中“整张 session 表面都经过 `_maybe_serialize_request()`”是完全一致的。

### 3. isolated retry 只覆盖特定错误

几组测试很清楚：

- `CancelledError`、5xx、`ClosedResourceError`、MCP 408 会切 isolated retry
- 4xx 不会
- 混合异常组也不会

所以 SDK 对“这是共享 session 故障”还是“这是业务级失败”分得比较克制。

## 三种 transport 在真实调用链里的差异

把 transport 和 shared session 语义放在一起看，会更清楚。

### `stdio`

- `create_streams()` 直接走 `stdio_client()`
- 连接成功后建立一个共享 `ClientSession`
- SDK 侧默认不做 session 请求串行化
- 也没有 streamable HTTP 那种 session-id 和 isolated retry 设计

### `SSE`

- `create_streams()` 走 `sse_client()`
- 仍然是共享 `ClientSession`
- 支持 `headers / timeout / sse_read_timeout / auth / httpx_client_factory`
- SDK 侧同样默认不打开 `_serialize_session_requests`

### `streamable HTTP`

- `create_streams()` 走 `streamablehttp_client()` 或容错版 `_streamablehttp_client_with_transport()`
- transport 会额外返回 `get_session_id`
- 共享 session 默认串行化请求
- `call_tool()` 失败时支持切 isolated session 重试
- cleanup 后会清空 `_get_session_id`

所以如果只用一句话压缩：

- `stdio` 和 `SSE` 主要解决“怎么建立共享 session”
- `streamable HTTP` 进一步解决“共享 session 不稳定时，怎么保住请求执行”

## 一个真实调用链怎么记

我现在会把 `streamable HTTP` 的工具调用记成这条线：

1. `connect()` 建立共享 transport 与共享 `ClientSession`
2. `call_tool()` 先在共享 session 上尝试执行
3. 这次 shared call 会先经过 `_maybe_serialize_request()`
4. 如果是共享 session 故障型错误，则切 isolated session 重试
5. isolated session 只服务这一次请求，随后销毁

这样记，比“支持 retry”更接近代码真实行为。

## 易错点

- 容易把 `_maybe_serialize_request()` 看成只影响 `call_tool()`，实际上 prompt/resource 相关方法也都走这层
- 容易把 isolated retry 理解成普通重试，实际上它换了 session 作用域
- 容易把 4xx 也当成共享 session 故障，但实现上只把 5xx、超时、连接断开等错误视为可隔离重试
- 容易忽略 `streamable HTTP` 是唯一默认打开共享 session 串行化的 transport

## 我的理解

`MCPServerStreamableHttp` 最值得记住的，不是它“也能通过 HTTP 连 MCP”，而是它把共享 session 当成一个需要被保护的长期对象来设计。

`_maybe_serialize_request()` 负责减少共享 session 内部冲突，isolated retry 负责在共享 session 已经不可靠时给单次请求一条逃生路径。这两层叠在一起，才构成它真正区别于 `stdio / SSE` 的地方。

## 相关笔记

- [[OpenAI Agents SDK MCP 连接管理与调用链]]
- [[OpenAI Agents SDK MCP Transport 与 Session 建立]]
- [[OpenAI Agents SDK MCP Message Handler 与 Session 消息流]]
- [[OpenAI Agents SDK tracing 结构与 span 语义]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
