---
tags:
  - 主题
  - OpenAI Agents SDK
  - MCP
  - 连接管理
  - 工具调用
type: topic
---

# OpenAI Agents SDK MCP 连接管理与调用链

## 这是什么

这篇笔记整理的是 `src/agents/mcp/` 这层真正稳定的骨架。

我现在更倾向于把它理解成三层：

- `MCPServer`：统一服务器抽象
- `MCPServerManager`：连接生命周期管理器
- `MCPUtil`：把 MCP tools 适配成 Agents SDK tools 的桥接层

## 为什么重要

- 很多人提到 MCP 时只关注“能不能接工具”
- 这套实现真正解决的其实是：连接怎么管、失败怎么降级、工具怎么并入 Runner、资源和 prompt 怎么从同一服务器表面暴露出来
- 测试看下来，MCP 在这套 SDK 里不是一个松散插件点，而是被认真纳入 runtime 的能力层

## 我现在看到的主线

我会先把它记成这条线：

1. 先定义若干 `MCPServer`
2. 用 `MCPServerManager` 连接并筛出 active servers
3. 运行时通过 `MCPUtil.get_function_tools()` 把 MCP tools 转成 Agents SDK tools
4. Runner 在正常 tool 调用流里调用这些 MCP tools
5. 除了 tools，server 还可以暴露 prompts、resources、resource templates

所以 MCP 在这里不是“外挂工具清单”，而是被包装成正式 runtime capability。

## `MCPServerManager` 的职责很明确

从 `manager.py` 看，最关键的不是“帮你 connect 一下”，而是这些运行时保证：

- connect 和 cleanup 保持在同一个 task 上
- 可以串行连接，也可以并行连接
- 并行连接时仍通过 worker task 保留 task affinity
- 失败 server 会被记录到 `failed_servers`
- `active_servers` 只暴露成功连接的那部分
- 支持 `reconnect(failed_only=True)` 做失败重试

测试里最有价值的一点是：它专门防守了“connect 和 cleanup 不在同一 task 导致底层 cancel scope 出错”这类问题。

这说明它面对的不是普通 Python 对象，而是真正有异步运行时约束的 MCP client。

## 为什么 `_ServerWorker` 很关键

`_ServerWorker` 把每个 server 的 `connect / cleanup` 串到一个专用队列里执行。

它的价值不是抽象优雅，而是实打实解决了：

- 同一个 server 的生命周期动作必须在同一任务上下文里跑
- 又希望多个 server 之间能并行建立连接

也就是说，这里不是简单 `gather(connect())`，而是“并行 + 每个 server 内部串行”的折中结构。

## `MCPServer` 抽象层不只管 tool

`server.py` 暴露的抽象面其实比“tool server”更宽：

- `list_tools()`
- `call_tool()`
- `list_prompts()`
- `get_prompt()`
- `list_resources()`
- `list_resource_templates()`
- `read_resource()`

这点和很多人对 MCP 的第一印象不一样。

在这套 SDK 里，MCP server 不只是函数调用端点，也是 prompt 和 resource 的统一来源。

## 连接实现的几个关键点

从 `server.py` 看，我现在最想记住这些细节：

- 支持 stdio、SSE、streamable HTTP 等不同 transport
- streamable HTTP 单独做了初始化通知失败容忍
- session 没初始化时，访问 tools/resources/prompts 会报 `Server not initialized`
- `require_approval` 可以是布尔值、always/never、按 tool name 的映射，甚至 callable
- `tool_meta_resolver` 可以给 MCP 调用补 `_meta`

这说明 server 层已经把 transport 差异、审批策略和 metadata 注入统一收口了。

## `MCPUtil` 才是 Runner 真正用到的桥

从 `util.py` 看，`MCPUtil` 的重点是把 MCPTool 转成 Agents SDK 能消费的 FunctionTool。

这里我现在最关心的点有三个：

- 聚合多个 server 时会检测重复 tool name
- 可以做 strict schema 处理
- 可以做 tool filter 和 tool metadata 解析

换句话说，Runner 并不是“直接调用 MCP server”，而是先把 MCP tool 表面转成自己统一的 tool 语义，再进入原有工具执行链。

## 测试暴露出的行为边界

### 1. Runner 真会把 MCP tool 当正式 tool 调用

`test_runner_calls_mcp.py` 说明：

- 模型产出某个 tool call 时，Runner 会去 MCP server 找同名工具
- 多个 MCP server 可以一起挂进 agent
- 如果 tool name 冲突，会直接报错
- 如果模型调用不存在的 MCP tool，会触发行为错误

这意味着 MCP tool 并没有走“特殊分支”，而是进入了统一 tool call 语义。

### 2. 工具过滤不是装饰功能

`test_tool_filtering.py` 说明：

- 既支持静态 allowlist/blocklist
- 也支持 sync / async 动态过滤
- 过滤函数能拿到 `run_context / agent / server_name`
- 过滤函数出错时，不会把整个 server 搞挂，而是跳过出问题的 tool

这让 MCP tool 暴露变成了“按 agent、按上下文裁剪能力面”的机制，而不是固定全量暴露。

### 3. 资源访问是 MCP 表面的正式部分

`test_mcp_resources.py` 说明：

- 未连接时访问 resource 会明确报 `Server not initialized`
- 已连接后，`list_resources / list_resource_templates / read_resource` 都是直接代理到底层 session
- resource/template 还支持 cursor 分页

这让我更愿意把 MCP 理解成“远程能力与知识面的统一接口”，而不只是 tool execution。

## 我现在怎么理解这条调用链

如果只看最核心的一步，可以先记：

- `Agent(mcp_servers=[...])`
- `MCPServerManager` 负责把 server 连接起来并筛出 active subset
- `Agent.get_mcp_tools()` / `MCPUtil` 把 server tools 转成 FunctionTool
- `Runner` 在 tool call 阶段像调用普通 tool 一样调用 MCP tool

这个结构的好处是：MCP 被吸收到现有 runtime 里，而不是在外面另起一套执行系统。

## 它和别的主题怎么分工

- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
  - 更偏架构边界与生态位置
- 这篇
  - 更偏连接管理、server 抽象和实际工具接入链

## 易错点

- 容易把 `MCPServerManager` 当成可有可无的辅助类，实际上它承担了 task affinity 和失败降级
- 容易把 MCP 理解成“只暴露 tools”，忽略 prompt/resource 也是正式表面
- 容易以为 Runner 直接调 server，实际上中间还有 `MCPUtil` 的 tool 适配层
- 容易忽略多 server 重名 tool 会直接冲突

## 我现在最想继续确认的点

- `server.py` 里不同 transport 的具体 session 建立差异
- tracing 是怎样把 MCP 调用并进 span 结构的
- approval 和 `_meta` 注入在真实调用链里如何与 tool execution 合流

## 相关笔记

- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK tracing 结构与 span 语义]]
- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
