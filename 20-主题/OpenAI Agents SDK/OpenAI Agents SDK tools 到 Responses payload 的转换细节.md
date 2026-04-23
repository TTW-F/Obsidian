---
tags:
  - 主题
  - OpenAI Agents SDK
  - Tools
  - Responses API
  - 源码
type: note
---

# OpenAI Agents SDK tools 到 Responses payload 的转换细节

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 里工具系统如何被翻译成 OpenAI Responses API 的请求载荷。

如果只看 `Agent.tools=[...]` 这一层，容易以为工具只是挂在 agent 上的一组对象；但从 `src/agents/models/openai_responses.py` 看，真正决定模型最终看到什么工具面的，是一整层转换逻辑。

## 为什么重要

- 这层决定模型到底以什么 schema 看见 function tool、search tool、shell、computer、MCP 和 handoff
- `tool_choice`、命名空间、defer loading、computer preview / GA 兼容，都会在这里变成底层 API 参数
- 如果想理解为什么工具系统和模型层在这套 SDK 里深度耦合，这一层是最直接的证据

## 转换入口为什么在 `OpenAIResponsesModel`

真正把工具系统接到 Responses API 的核心位置在：

- `src/agents/models/openai_responses.py`

这里在构造 `responses.create(...)` 参数时，会先做几步关键转换：

- `Converter.convert_tool_choice(...)`
- `Converter.convert_tools(...)`
- `Converter.get_response_format(...)`

也就是说，tools、tool choice 和 output schema 不是分开独立塞进去的，而是在同一层里一起整理。

## `FunctionTool` 为什么是最基础映射单元

`tool.py` 里的 `FunctionTool` 代表的是最通用、最本地的工具抽象。

它的核心字段包括：

- `name`
- `description`
- `params_json_schema`
- `strict_json_schema`
- `defer_loading`
- `needs_approval`

到了 `openai_responses.py` 的 `_convert_function_tool()` 里，这些字段会被直接翻译成 Responses function tool payload：

- `name`
- `parameters`
- `strict`
- `type="function"`
- `description`

如果开启了 `defer_loading=True`，还会额外加上：

- `defer_loading`

所以 function tool 不是通过“再包一层 prompt 描述”接入模型，而是明确进入了 Responses 的 tool schema。

## 为什么 handoff 也会被转成 function tool

`_convert_handoff_tool()` 很值得重点看。

它会把一个 `Handoff` 直接转换成：

- `type="function"`
- `name=handoff.tool_name`
- `parameters=handoff.input_json_schema`
- `description=handoff.tool_description`

这说明在 Responses 请求载荷层面，handoff 和普通 function tool 的外形非常接近。

也正因为如此，模型才会把 handoff 当作一种可调用工具来选择。

## `convert_tools()` 为什么更像工具面编译器

`Converter.convert_tools()` 是整个工具转换层里最值得重点看的函数。

它除了遍历 `tools` 和 `handoffs` 之外，还同时处理了：

- 工具类型判断
- includes 收集
- namespace 分组
- deferred tool search 的兼容
- computer tool 的 preview / GA 选择

所以它更像一个“工具面编译器”，而不只是 `for tool in tools` 的简单映射。

## 命名空间和 deferred-loading 为什么都要在这里解决

这套 SDK 有一个很有辨识度的点：命名空间工具不是在更上层靠命名约定组织，而是直接在转换层被组合。

`_tool_identity.py` 和 `convert_tools()` 一起处理了这些事：

- function tool 的 lookup key
- namespaced tool 的 qualified name
- deferred top-level tool 的 synthetic key
- namespace description 一致性检查

然后 `convert_tools()` 会把属于同一命名空间的 function tools 聚合成一个：

- `type="namespace"`
- `name=<namespace>`
- `description=<namespace description>`
- `tools=[...]`

而 deferred-loading tool 也不是简单“不发给模型”，而是会配合 `tool_search` 和特殊 lookup 规则一起工作。

这说明 namespace 和 defer loading 都不是文档概念，而是实际进入 Responses payload 的 wire shape。

## 不同工具类型为什么会被映射成不同 Responses 内建工具

`_convert_tool()` 里可以直接看到一张映射表。

典型对应关系包括：

- `FunctionTool` -> function tool payload
- `WebSearchTool` -> `type="web_search"`
- `FileSearchTool` -> `type="file_search"`
- `ComputerTool` -> `type="computer"` 或 preview computer payload
- `CustomTool` -> `tool.tool_config`
- `HostedMCPTool` -> `tool.tool_config`
- `ApplyPatchTool` -> `type="apply_patch"` 或自定义 config
- `ShellTool` -> `type="shell"`
- `LocalShellTool` -> `type="local_shell"`
- `ToolSearchTool` -> `type="tool_search"`

这张映射表本身就说明：OpenAI Agents SDK 的工具层并不是独立于模型 API 的中立抽象，它已经明确向 Responses 内建工具面靠拢。

## `tool_choice` 为什么也要经过兼容转换

`Converter.convert_tool_choice()` 处理的不只是 `auto / required / none`。

它还会处理：

- MCP tool choice
- file search / web search
- computer / computer_use / computer_use_preview
- image generation / code interpreter
- 命名 function tool

同时它还会做一层校验：

- required tool choice 是否和 deferred tool search surface 冲突
- named tool choice 是否指向 namespace wrapper
- named tool choice 是否命中了 deferred-only function tool

所以 `tool_choice` 不是原样透传的字符串参数，而是一层有语义约束的转换结果。

## output schema 为什么也在同一层进入 payload

`Converter.get_response_format()` 会把 `output_schema` 转成：

- `text.format.type="json_schema"`
- `name="final_output"`
- `schema=...`
- `strict=...`

这一步和工具转换放在一起很说明问题。

因为它表明在 OpenAI Agents SDK 里：

- tools
- handoffs
- tool_choice
- output schema

其实都是“模型请求 shape”的一部分。

## 一个具体场景怎么理解这层

假设某次 run 同时需要：

- 暴露 function tools
- 暴露 handoff
- 带 namespace tool
- 开启 deferred-loading tool
- 指定 structured output

对上层运行时来说，这些只是“本轮工具面和输出规则”。但到 Responses API 这一层，它们必须被编译成一个合法、一致、可兼容的请求形状。

这个场景能帮助我记住：这一层真正做的是协议编译，而不是工具注册。

## 最该记住的点

- 工具不是 agent 内部对象，最终都要被编译成 Responses payload
- handoff 在请求载荷层和 function tool 外形很接近
- namespace、defer loading、tool search 都是在转换层真正落地
- `tool_choice` 不是简单字符串，而是带兼容和校验逻辑的转换结果

## 易错点

- 容易把工具理解成 agent 内部对象，忽略它们最终必须被编译成 Responses payload
- 容易把 handoff 和 function tool 完全分开想，但在请求载荷层它们外形非常接近
- 容易以为 `tool_choice` 是原样透传，忽略它在这里会被重写、校验和兼容转换
- 容易低估 `_tool_identity.py` 的价值

## 我的理解

OpenAI Agents SDK 的工具层，真正难的地方不是“支持多少种工具”，而是它怎样把本地运行时抽象、OpenAI 内建工具面、handoff 语义和 tool search 都压进同一套 Responses 请求形状里。

所以这一层本质上不是工具注册表，而是一层协议编译器。

## 相关笔记

- [[OpenAI Agents SDK 模型抽象层与 Provider 路由]]
- [[OpenAI Agents SDK handoff 交接语义与输入迁移]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
