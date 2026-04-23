---
tags:
  - 主题
  - OpenAI Agents SDK
  - Model
  - Provider
  - 源码
type: note
---

# OpenAI Agents SDK 模型抽象层与 Provider 路由

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 模型层的核心抽象：`Model`、`ModelProvider`、`OpenAIProvider`、`MultiProvider`，以及它们怎样把一次 agent run 接到具体模型后端。

如果只看 `Agent.model="gpt-4.1"` 这种表面写法，很容易以为模型层只是一个字符串参数；但从 `src/agents/models/` 看，这里其实是一层独立的适配与路由系统。

## 为什么重要

- 这层决定 `Runner` 最终把请求交给谁，以及工具、schema、streaming 怎样被翻译成底层模型 API 载荷
- README 里说的 provider-agnostic，不是抽象口号，而是由 `ModelProvider` 和 `MultiProvider` 这套路由层落地
- 如果想理解为什么这套 SDK 默认偏 OpenAI Responses API、又同时保留多 provider 扩展能力，模型层是最直接的源码入口

## `Model` 抽象真正统一了什么

在 `src/agents/models/interface.py` 里，`Model` 抽象要求实现两件核心能力：

- `get_response(...)`
- `stream_response(...)`

这两个方法的输入已经不是底层厂商私有格式，而是 SDK 统一过的运行时对象：

- system instructions
- Responses 格式的 input items
- `ModelSettings`
- tools
- handoffs
- output schema
- tracing
- `previous_response_id` / `conversation_id`

这说明模型层吃到的不是“原始 prompt 字符串”，而是 agent runtime 已经整理过的一整套执行上下文。

## `ModelProvider` 和 `MultiProvider` 分别在解决什么

### `ModelProvider`

同一个文件里，`ModelProvider` 只暴露一个关键入口：

- `get_model(model_name)`

也就是说，provider 的职责不是直接执行一次请求，而是根据模型名返回一个可调用的 `Model` 实例。

这个分层很重要：

- `Model` 关心一次请求怎么发
- `ModelProvider` 关心这个名字该由谁来接

### `MultiProvider`

`src/agents/models/multi_provider.py` 把 provider-agnostic 这件事真正落到了模型名路由上。

它的默认思路是：

- 没前缀，走 OpenAI provider
- `openai/...`，通常也走 OpenAI provider
- `litellm/...`，走 LiteLLM provider
- `any-llm/...`，走 AnyLLM provider

同时它还支持：

- 自定义 `provider_map`
- `openai_prefix_mode`
- `unknown_prefix_mode`

这意味着模型字符串不只是模型 ID，也承担了一层路由语义。

## `OpenAIProvider` 为什么不只是包一层 client

`src/agents/models/openai_provider.py` 里能看到，这套 SDK 默认还是围绕 OpenAI 做了最完整的一层接入。

它主要做三件事：

- 延迟创建 `AsyncOpenAI` client，避免没配置 API key 时提前报错
- 根据配置选择 Chat Completions 还是 Responses API
- 在 websocket transport 场景下缓存 `OpenAIResponsesWSModel`，复用长连接

这里最值得记住的一点是：`OpenAIProvider` 不只是“包一下 OpenAI client”，而是在 transport、连接复用、默认模型和资源释放之间做统一管理。

## `ModelSettings` 为什么是模型调用参数层

`src/agents/model_settings.py` 不是简单参数包，而是 SDK 统一模型调用参数的地方。

这里集中定义了：

- `tool_choice`
- `parallel_tool_calls`
- `truncation`
- `max_tokens`
- `reasoning`
- `verbosity`
- `response_include`
- `extra_headers` / `extra_body` / `extra_query`
- retry 配置

最值得记住的一点是 `resolve()`：agent 级默认设置和本次调用 override 会在这里合并，而不是散落在各处临时拼装。

## `OpenAIResponsesModel` 为什么是最重的一层适配

`src/agents/models/openai_responses.py` 的体量很大，核心原因是它承担了最多的协议翻译工作。

它不只是“调一下 Responses API”，还负责把运行时里的对象转换成 Responses 请求需要的具体载荷，包括：

- tools 转换
- handoffs 转成 function tool 形态
- output schema 转成 `json_schema` response format
- `tool_choice` 转成 Responses tool choice
- streaming 事件转回 SDK 统一事件流

所以这层更像“Responses API 适配器 + 运行时协议转换器”。

## 一个具体场景怎么理解模型层

假设某次 run 同时需要：

- 带工具 schema
- 支持 handoff
- 使用 structured output
- 开启 streaming
- 保留 tracing

对主循环来说，这仍然只是“一次模型调用”。但对模型层来说，已经涉及 provider 路由、参数合并和协议转换。

这个场景能帮助我记住：模型层不是薄封装，而是主循环和底层模型 API 之间的翻译层。

## 常见执行链怎么记

把模型层放回主线里，可以先记成下面这条链：

1. `Agent` 提供 `model` 和 `model_settings`
2. `Runner` / `turn_preparation` 解析出本轮要用的模型名字和设置
3. `ModelProvider.get_model()` 返回具体 `Model`
4. `Model.get_response()` 或 `stream_response()` 把 runtime 对象翻译成底层请求
5. 底层响应再被翻译回 SDK 的 `ModelResponse` 或 stream events

## 最该记住的点

- `model` 不是单纯字符串配置，背后还有 provider 路由和协议转换
- `Model`、`ModelProvider`、`MultiProvider` 分别解决不同层的问题
- `OpenAIResponsesModel` 是请求载荷层面的重适配器
- 模型层和工具系统不是松耦合关系，在 Responses API 路径里它们其实深度绑定

## 易错点

- 容易把 `model` 当成单纯字符串配置
- 容易把 provider-agnostic 理解成“随便换后端”，而忽略不同前缀模式和 unknown prefix 策略
- 容易只看 `OpenAIProvider`，不看 `ModelSettings` 和 `OpenAIResponsesModel`
- 容易把模型层看成和工具系统分离

## 我的理解

OpenAI Agents SDK 的模型层，本质上是在做两件事：

- 用 `Model` / `ModelProvider` 把“模型后端”从运行时主链里抽象出来
- 用 `OpenAIResponsesModel` 把运行时里的工具、schema、streaming 和 tracing 真正接到 Responses API

所以这层既是抽象层，也是协议落地层。

## 相关笔记

- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
