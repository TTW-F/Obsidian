---
tags:
  - 主题
  - OpenAI Agents SDK
  - Realtime
  - 会话
  - 事件流
type: topic
---

# OpenAI Agents SDK Realtime 会话与事件流

## 这是什么

这篇笔记整理的是 `src/agents/realtime/` 这组实现最值得先抓住的骨架。

我现在更倾向于把它理解成一套“长连接会话运行时”，而不是普通 `Runner.run()` 的实时版包装层。

## 为什么重要

- 普通 `Runner` 更像一次 run 的多轮推进
- `RealtimeRunner` 直接返回一个可持续交互的 `RealtimeSession`
- 真正的重点不只是模型会流式输出，而是本地会话层如何维护 history、工具调用、guardrail 和 agent handoff

## 我现在看到的主线

从 `runner.py` 看，`RealtimeRunner` 的角色很克制：

- 接收 `starting_agent`
- 选择一个 `RealtimeModel`
- 创建并返回 `RealtimeSession`

也就是说，Realtime 的核心不在 runner 本身，而在 session。

## `RealtimeSession` 才是运行时中心

从 `session.py` 看，`RealtimeSession` 同时承担了几层职责：

- 持有当前 agent 与 context wrapper
- 维护本地 `_history`
- 维护 `_event_queue`，把模型层事件转成 SDK 层 session event
- 跟踪 pending tool call、guardrail task、tool task
- 管理连接生命周期：`__aenter__`、`__aiter__`、`close()`

这意味着 Realtime 不是“收一段音频，拿一段输出”这么简单，而是把本地状态机放在了 session 上。

## 一条最值得记住的调用链

我现在会把它先记成这条线：

1. `RealtimeRunner.run()` 创建 `RealtimeSession`
2. `RealtimeSession.__aenter__()` 给 model 注册 listener
3. session 计算 agent 对应的初始 model settings
4. 调用 `model.connect(...)` 建立长连接
5. 后续通过 `send_message()`、`send_audio()`、`interrupt()` 与模型持续双向通信
6. 模型事件进入 `on_event()`，再被翻译成更高层的 realtime session event

这条线和普通 `run_internal` 的差异在于：一次连接里会承载多次输入、工具、打断和切换，而不是每轮都重新建立完整 run。

## `RealtimeAgent` 的约束很关键

从 `agent.py` 看，`RealtimeAgent` 明显比普通 `Agent` 更收敛。

我现在确认的几个限制是：

- 不支持单 agent 级别的 model choice
- 不支持单 agent 级别的 model settings
- 不支持 structured output
- 不支持普通 agent 那套 tool use behavior 配置

这说明 Realtime 的设计重心不是“让每个 agent 自由配置一切”，而是让同一 session 下的一组 agent 共享一个持续连接的模型层。

## 为什么说它是“会话运行时”

`session.py` 里最能说明问题的，不是 send API，而是这些状态：

- `_history`
- `_pending_tool_calls`
- `_interrupted_response_ids`
- `_item_transcripts`
- `_guardrail_tasks`
- `_tool_call_tasks`

这几个对象放在一起，说明它在解决的是：

- 历史如何在本地持续存在
- 工具调用如何异步并入实时流
- guardrail 如何在增量 transcript 上触发
- interrupt 之后哪些 response 已经失效

所以它更像一个本地编排器，而不是单纯的 websocket wrapper。

## 目录里各文件大致在干什么

- `runner.py`
  - 创建 session，是入口层
- `session.py`
  - 真正的状态机与事件桥接层
- `agent.py`
  - RealtimeAgent 对象与配置边界
- `model.py`、`openai_realtime.py`
  - 模型抽象层与默认 OpenAI WebSocket 实现
- `events.py`、`model_events.py`
  - SDK 事件与底层模型事件的类型层
- `model_inputs.py`
  - 发往模型层的输入对象
- `items.py`
  - history item 与消息片段的表示
- `handoffs.py`
  - realtime 语境下的 agent 切换

## 它和普通运行时的边界

普通运行时更像：

- 一次 run
- 内部多轮推进
- 直到 final output 结束

Realtime 这套更像：

- 一个持续 session
- 输入、音频、工具、打断都在里面流动
- session 本身比单轮 output 更重要

所以如果后面继续拆，我会优先把它和 `run_internal/` 做对照，而不是把它当作 sandbox 或 voice 的附属小模块。

## 易错点

- 容易把 `RealtimeRunner` 当成主逻辑，实际上它更像 session 工厂
- 容易只盯 `send_audio()`，忽略真正复杂的是 history、tool call、guardrail 和 event queue
- 容易把 RealtimeAgent 当普通 Agent 来理解，忽略它在模型配置上的收缩

## 我现在最想继续确认的点

- `model_events.py` 到 `events.py` 的事件映射细节
- `handoffs.py` 在 realtime session 中如何切换 active agent
- `openai_realtime.py` 里默认 WebSocket model 到底承担多少协议转换

## 相关笔记

- [[OpenAI Agents SDK Voice 与 Realtime 的边界]]
- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK handoff 交接语义与输入迁移]]
- [[OpenAI Agents SDK RunItem 与 stream event 数据结构]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
