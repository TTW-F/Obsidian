---
tags:
  - 主题
  - OpenAI Agents SDK
  - MCP
  - Message Handler
  - tracing
type: topic
---

# OpenAI Agents SDK MCP Message Handler 与 Session 消息流

## 这是什么

这篇笔记专门整理 `src/agents/mcp/server.py` 里的 `message_handler`、`ClientSession` 消息流，以及它和 tracing 之间到底是什么关系。

我现在更倾向于把它理解成两个并行但不重合的观测面：

- `message_handler`
  - 面向底层 MCP session 消息
- tracing
  - 面向 Agents SDK 运行时里的工具列表获取与函数执行

## 为什么重要

- 很容易以为“既然有 session message handler，它应该天然进入 tracing”
- 但从实际调用链看，message handler 和 tracing 并不在同一层
- 如果不分清这两条链，就会把“底层协议消息观测”和“SDK 运行时 span 观测”混成一件事

## `message_handler` 在代码里是怎样进入系统的

`_MCPServerWithClientSession.__init__()` 会把外部传入的 `message_handler` 保存到 `self.message_handler`。

真正接进底层 `ClientSession` 的位置有两个：

- 共享 session 建立时，在 `connect()` 里传给 `ClientSession(..., message_handler=self.message_handler)`
- isolated retry 建立临时 session 时，在 `_isolated_client_session()` 里也同样传进去

这意味着一件很关键的事：

- message handler 不只对初始共享 session 生效
- 对 streamable HTTP 的 isolated retry session 也同样生效

所以它不是“连接期一次性配置”，而是 server 在创建任意 `ClientSession` 时都会透传的观测钩子。

## 现有测试实际保证了什么

`tests/mcp/test_message_handler.py` 很克制，但信息很明确：

- 测试确认 `message_handler` 会被保存到 server 实例
- 测试确认 `connect()` 时会原样传给 `ClientSession`
- 测试覆盖了 `MCPServerSse`、`MCPServerStreamableHttp`、`MCPServerStdio`

换句话说，SDK 当前对 `message_handler` 的正式承诺是：

- 三种 transport 都支持把 handler 透传到底层 session

但测试没有承诺更强的事情，例如：

- handler 一定会收到哪些消息类型
- SDK 自己会不会消费这些消息
- handler 输出会不会进入 tracing

所以这层语义现在更像“保留底层 MCP session 可观测性”，而不是“SDK 已定义一套稳定 message 事件模型”。

## session 消息流怎么理解

从 `connect()` 这条线看，MCP server 建连会先做三步：

1. `create_streams()` 创建 transport 对应的 `read / write`
2. 用这对流创建 `ClientSession`
3. 调 `session.initialize()`

这里的 `message_handler` 是交给 `ClientSession` 的，所以它所观察的是：

- 由底层 session 收到或处理的 `SessionMessage`

而不是：

- Agent 的 turn 事件
- FunctionTool 的包装事件
- tracing span 事件

所以 message flow 的真正边界是“协议层 session 消息”，不是整个 Agents SDK runtime。

## 三种 transport 下，message flow 的差异怎么记

### `stdio`

- handler 挂在通过 `stdio_client()` 建出来的共享 `ClientSession` 上
- 更像本地子进程 MCP 对话的底层消息观察

### `SSE`

- handler 挂在通过 `sse_client()` 建出来的共享 `ClientSession` 上
- transport 本身多了 HTTP client 配置，但 handler 接入点没有变化

### `streamable HTTP`

- handler 同样挂在共享 `ClientSession` 上
- 如果工具调用切到 isolated retry，会在临时 `ClientSession` 上再次挂同一个 handler
- 这意味着它观测到的并不只是“长期共享 session 的消息”，也可能包含“隔离重试那次临时 session 的消息”

所以 transport 差异主要不在 handler 接口本身，而在“到底会有多少种 session 生命周期被它观测到”。

## initialized notification 说明了 message flow 和 handler 不是一回事

`_InitializedNotificationTolerantStreamableHTTPTransport._handle_post_request()` 很值得记。

这里直接检查的是：

- `ctx.session_message.message`

如果它识别到这是 `notifications/initialized`：

- 发送失败时只记 warning
- 不让整个 transport 直接报废

这段逻辑说明：

- session message 在 transport 层就已经被看见和分流了
- 某些消息的处理策略甚至发生在 `ClientSession` 之下

所以不能把 `message_handler` 理解成“所有 session 消息都会先经过的唯一入口”。至少在 streamable HTTP 这条线上，transport 自己也会根据 message 类型做特殊处理。

## tracing 真正发生在哪

如果把 message handler 和 tracing 放在一起看，真正的 tracing 落点主要在 `src/agents/mcp/util.py`。

### 1. 拉取工具列表时会产生 `mcp_tools_span`

`MCPUtil.get_function_tools()` 会在 `with mcp_tools_span(server=server.name)` 里调用 `server.list_tools()`，然后把工具名写进 span result。

这说明 tracing 观测的是：

- “这个 server 暴露了哪些工具”

而不是：

- list_tools 过程里来回流动了哪些底层 session message

### 2. 工具真正执行时，信息写进当前 function span

`MCPUtil.invoke_mcp_tool()` 在完成 `server.call_tool()` 后会读取 `get_current_span()`。

如果当前 span 是 `FunctionSpanData`，它会：

- 在允许暴露敏感数据时写入 `output`
- 写入 `mcp_data = {"server": server.name}`

这和 `tests/mcp/test_mcp_tracing.py` 完全一致：测试验证的是 function span 上带有 `mcp_data.server`，以及拉取工具列表时出现 `mcp_tools` span。

所以 tracing 记录的是：

- 这次工具调用属于哪个 MCP server
- 工具执行结果是什么

而不是：

- 这次调用过程中 session 收到了哪些 notification / request / responder

## message handler 和 tracing 的关系怎么压缩

我现在会这样记：

- `message_handler`
  - 协议层 session 消息旁路
- tracing
  - runtime 层工具发现与工具执行观测

二者会围绕同一次 MCP 调用出现，但并不互相驱动。

更具体一点说：

- tracing 不依赖 `message_handler`
- `message_handler` 的输出也不会自动进入 tracing span
- SDK 当前没有把 `SessionMessage` 映射成专门的 tracing span 类型

## 一个真实调用链怎么记

把一次 MCP 工具调用压成这条线会比较稳：

1. transport 创建 `read / write`
2. server 创建 `ClientSession(message_handler=...)`
3. `session.initialize()` 建立会话
4. `MCPUtil.get_function_tools()` / `invoke_mcp_tool()` 在 runtime 层包上 tracing
5. `message_handler` 继续在底层观察 session 消息
6. tracing 最后只记录工具发现和函数执行结果，不记录完整消息流

这个顺序能帮我避免把“消息观测”和“运行时 span”混成一个系统。

## 易错点

- 容易把 `message_handler` 当成 tracing 的底层输入，当前实现里不是
- 容易以为只有共享 session 才会带 handler，实际上 isolated retry session 也会带
- 容易把 transport 层对 initialized notification 的特殊处理误认为是 handler 行为
- 容易以为 SDK 已经对 session message 做了稳定事件建模，现有实现更多还是透传底层能力

## 我的理解

OpenAI Agents SDK 在 MCP 这一层保留了两种不同粒度的观测手段。

`message_handler` 更像协议层听诊器，让你看到 session 级消息；tracing 更像 runtime 结构化记录，只关心“列了哪些工具、执行了哪个工具、结果属于哪个 MCP server”。它们围绕同一条调用链工作，但目前还没有被合并成一套统一消息追踪系统。

## 相关笔记

- [[OpenAI Agents SDK MCP 请求串行化与共享 Session 语义]]
- [[OpenAI Agents SDK MCP Transport 与 Session 建立]]
- [[OpenAI Agents SDK MCP 连接管理与调用链]]
- [[OpenAI Agents SDK tracing 结构与 span 语义]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
