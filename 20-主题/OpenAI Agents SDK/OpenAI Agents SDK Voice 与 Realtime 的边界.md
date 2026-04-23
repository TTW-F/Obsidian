---
tags:
  - 主题
  - OpenAI Agents SDK
  - Voice
  - Realtime
  - 边界
type: note
---

# OpenAI Agents SDK Voice 与 Realtime 的边界

## 这是什么

这篇笔记专门回答一个很容易混淆的问题：`src/agents/voice/` 和 `src/agents/realtime/` 都处理音频与流式交互，但它们到底是不是同一层能力。

我现在的结论是：两者相关，但不在同一层。`voice/` 是偏应用层的语音管线，`realtime/` 是偏运行时层的持续会话基础设施。

## 为什么重要

- 如果把两者混成一个概念，就很容易误判源码入口和后续阅读顺序
- 这两个目录都接触音频、WebSocket、流式事件，但解决的问题并不一样
- 搞清楚边界之后，后面要补笔记、看示例或做技术选型都会更稳

## 最短结论

- `voice/` 解决的是“怎样把语音接进现有 agent 工作流，再把结果说出来”
- `realtime/` 解决的是“怎样在一个持续连接里维护实时会话、工具、guardrail、handoff 和中断”

所以前者更像一条语音装配线，后者更像一套实时会话运行时。

## `voice/` 的中心对象是 `VoicePipeline`

`voice/pipeline.py` 的结构非常直接：

1. STT 把音频转成文本
2. workflow 处理文本
3. TTS 把文本变回音频

即使是 `StreamedAudioInput`，它也只是“检测到一轮转写就跑一次 workflow”，并没有把整条语音对话放进统一 session 状态机里。

## `realtime/` 的中心对象是 `RealtimeSession`

`realtime/runner.py` 只是创建 session，真正复杂的是 `realtime/session.py`。

这层会持续维护：

- `_history`
- `_pending_tool_calls`
- `_guardrail_tasks`
- `_tool_call_tasks`
- `_interrupted_response_ids`
- agent 更新和 session settings 更新

也就是说，`realtime/` 的主要问题不是转写或播音，而是持续连接里的本地编排。

## 它们连接普通 agent runtime 的方式不同

`voice/` 通过 `SingleAgentVoiceWorkflow` 复用普通 `Runner.run_streamed()`：

- 每次拿到一段 transcript
- 跑一次普通 agent 流式执行
- 从 response 里抽取文本 delta
- 更新 input history，等待下一轮 transcript

`realtime/` 则不是围着普通 `Runner` 转，而是有自己的一套 `RealtimeRunner -> RealtimeSession -> RealtimeModel` 结构。

## 两者都碰到“流式音频”，但位置不同

`voice/` 里的流式音频主要出现在两个地方：

- 输入端：`StreamedAudioInput`
- 输出端：`StreamedAudioResult`

它关心的是一轮语音怎样被切分、转写、合成和顺序播放。

`realtime/` 里的流式音频则是实时会话协议的一部分：

- `send_audio()` 持续把音频送进模型
- session 直接收到模型侧音频、文本、工具和状态事件

它关心的是一个持续会话里音频与其他事件如何并存。

## 真正的耦合点在哪里

源码层最值得记住的结论是：`voice/` 和 `realtime/` 没有明显的直接 import 耦合。

我现在看到的关系更像三层：

1. 概念层有相邻性
   - 都处理音频、流式事件、WebSocket
2. 协议层有复用
   - `voice/models/openai_stt.py` 的流式转写会连 `wss://api.openai.com/v1/realtime?intent=transcription`
3. SDK 运行时层彼此独立
   - `voice/` 没直接复用 `RealtimeSession`
   - `realtime/` 也没建立在 `VoicePipeline` 上

这说明它们共享的是底层平台能力的一部分，不是同一个 SDK 子系统。

## interruption 是一个很好的分界点

`voice` 文档明确提到：`StreamedAudioInput` 当前没有内建 interruption handling。

而 `realtime/session.py` 明确暴露了：

- `interrupt()`
- `_interrupted_response_ids`
- 对被中断 response 的本地状态管理

所以如果问题变成“实时插话、中断恢复、同一连接里继续工具执行”，那重点应该转去 `realtime/`，不是继续深挖 `voice/`。

## history 语义也不一样

`voice/` 的 history 更像 workflow 自己决定要不要保留的上下文。

例如 `SingleAgentVoiceWorkflow` 通过 `_input_history` 和 `result.to_input_list()` 续接前文，但这本质上还是普通 `Runner` 的输入历史。

`realtime/` 的 history 则是 session 级本地状态，和工具调用、handoff、guardrail 一起被持续维护。

## 怎么选阅读入口

- 想看“语音输入怎么接 agent 再播出来”，先读 `voice/`
- 想看“一个实时会话怎么持续收发消息、音频、工具和中断”，先读 `realtime/`
- 想看 OpenAI 流式转写协议在 SDK 里怎么落地，可以把 `voice/models/openai_stt.py` 当成和 `realtime/` 相邻的协议样本

## 易错点

- 容易因为 `voice` 的流式 STT 连接了 realtime transcription 接口，就误以为整个 `voice/` 建立在 `realtime/` 上
- 容易把两者都归类成“语音 agent”，忽略一个偏语音管线，一个偏实时运行时
- 容易拿 `VoicePipeline` 去对比 `RealtimeRunner`，其实更合理的对比是“应用管线”对“会话运行时”

## 我的理解

这两块代码最适合这样记：

- `voice/` 让现有 agent 更容易长出耳朵和嘴
- `realtime/` 让 agent 拥有持续在线的实时会话身体

两者当然会在音频和流式协议上相遇，但它们的设计重心并不重合。

## 相关笔记

- [[OpenAI Agents SDK Voice 输入输出管线]]
- [[OpenAI Agents SDK Realtime 会话与事件流]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
