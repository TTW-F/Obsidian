---
tags:
  - 主题
  - OpenAI Agents SDK
  - Voice
  - 语音
  - Pipeline
type: note
---

# OpenAI Agents SDK Voice 输入输出管线

## 这是什么

这篇笔记整理 `src/agents/voice/` 这组实现最值得先抓住的主线：一段音频怎样经过转写、agent 工作流和语音合成，最后重新变成可播放的输出流。

我现在更倾向于把它理解成一条偏应用层的语音装配线，而不是一个完整的实时会话运行时。

## 为什么重要

- `voice/` 是 Agents SDK 里最直接把文本 agent 能力包进语音交互的一层
- 它把语音输入、文本工作流和语音输出拆成了清楚的三段接口，方便替换 STT、TTS 和中间 workflow
- 如果不先看清这条管线，很容易把它和 `realtime/` 混成同一种“语音 agent 基础设施”

## 核心概念

可以先把 `VoicePipeline` 记成固定三步：

1. `STTModel` 把音频转成文本
2. `VoiceWorkflowBase` 处理文本，通常内部会跑 `Runner.run_streamed()`
3. `TTSModel` 把文本增量转回音频

`pipeline.py` 里这个结构非常直白，所以 `voice/` 的重点不是复杂状态机，而是模块拼装和流式交接。

## 单次输入和流式输入是两条分支

`VoicePipeline.run()` 只区分两种输入：

- `AudioInput`
  - 已经拿到完整音频缓冲区，适合预录音频或 push-to-talk
- `StreamedAudioInput`
  - 音频块持续进入，STT session 负责检测一轮何时结束

这两个分支最后都会落到同一件事上：拿到一段转写文本，然后执行 workflow。

## 单次输入的主线

`_run_single_turn()` 的路径最简单：

1. `_process_audio_input()` 调用 `STTModel.transcribe()`
2. 把整段文本交给 `workflow.run(input_text)`
3. workflow 逐步产出文本 chunk
4. `StreamedAudioResult._add_text()` 把文本切片后交给 TTS
5. 输出 `turn_ended` 和 `session_ended`

这里的“session”更像一次语音处理任务的生命周期，不是 `realtime/` 那种长连接会话对象。

## 流式输入的主线

`_run_multi_turn()` 稍复杂一点，但仍然是串接思路：

1. 先执行可选的 `workflow.on_start()`，用于欢迎语之类的预输出
2. `STTModel.create_session()` 创建流式转写 session
3. `transcribe_turns()` 持续吐出一轮轮文本
4. 每拿到一轮文本，就执行一次 `workflow.run(input_text)`
5. 每轮结束后触发 `output._turn_done()`

关键点在于：流式模式并不会维护一个统一的语音会话状态机，而是“每识别到一轮，就跑一次 workflow”。

## `workflow` 才是和 agent runtime 的连接点

`workflow.py` 把 `voice/` 和普通 Agents runtime 接在一起。

其中最值得记住的是 `SingleAgentVoiceWorkflow`：

- 把每次转写追加进 `_input_history`
- 用 `Runner.run_streamed()` 跑当前 agent
- 通过 `VoiceWorkflowHelper.stream_text_from()` 只提取 `response.output_text.delta`
- 本轮结束后用 `result.to_input_list()` 回写 history
- 同时更新 `result.last_agent`，让 handoff 后的 agent 成为下一轮起点

这说明 `voice/` 本身并不重新实现 agent 编排，它复用的是普通文本运行时。

## `StreamedAudioResult` 负责把文本变成有序音频流

真正把文本转成可播放结果的是 `result.py`。

我会先记住它做了三件事：

- 用 `text_splitter` 把增量文本切成适合合成的小段
- 为每段文本启动独立 TTS 任务
- 用 `_dispatch_audio()` 保证各段音频仍按原文本顺序输出

这块设计很实用，因为 workflow 可能持续吐字，而 TTS 需要尽早开工，但最终播放顺序不能乱。

## `voice/models/` 的默认 OpenAI 实现

默认 provider 在 `voice/models/`：

- `openai_model_provider.py`
  - 默认 STT 是 `gpt-4o-transcribe`
  - 默认 TTS 是 `gpt-4o-mini-tts`
- `openai_tts.py`
  - 走 `client.audio.speech.with_streaming_response.create(...)`
- `openai_stt.py`
  - 静态音频用 `client.audio.transcriptions.create(...)`
  - 流式音频自己建 websocket，连接 `wss://api.openai.com/v1/realtime?intent=transcription`

这里很值得注意：`voice` 的流式转写虽然复用了 Realtime API 的转写能力，但它没有直接依赖 `agents.realtime` 的会话层。

## 事件模型比 `realtime/` 简单很多

`events.py` 只有三类事件：

- `VoiceStreamEventAudio`
- `VoiceStreamEventLifecycle`
- `VoiceStreamEventError`

生命周期也只有：

- `turn_started`
- `turn_ended`
- `session_ended`

这和 `realtime/session.py` 里那套 history、tool call、guardrail、interrupt、handoff 事件树不是一个复杂度。

## 一个最容易记住的例子

如果用户说一句话，`voice/` 里发生的事情可以先记成：

1. 麦克风音频进入 `AudioInput` 或 `StreamedAudioInput`
2. STT 产出一轮文本
3. workflow 用这段文本跑 agent
4. agent 产出的文本 delta 被送进 TTS
5. TTS 逐块吐出 PCM 音频
6. 应用层消费 `result.stream()` 来播放

## 常见操作 / 用法

- 想替换语音模型，优先看 `STTModel`、`TTSModel`、`VoiceModelProvider`
- 想保留多轮上下文，重点看 `SingleAgentVoiceWorkflow` 如何维护 `_input_history`
- 想控制输出节奏，重点看 `TTSModelSettings.text_splitter` 和 `buffer_size`
- 想看语音 tracing，重点看 `VoicePipelineConfig` 里的 `group_id`、敏感数据开关和 `workflow_name`

## 易错点

- 容易把 `VoicePipeline` 当成 realtime session 的高层封装，但它实际上走的是 `STT -> workflow -> TTS`
- 容易以为流式输入就等于内建打断处理，文档明确说 `StreamedAudioInput` 没有内建 interruption handling
- 容易忽略 `SingleAgentVoiceWorkflow` 是靠普通 `Runner.run_streamed()` 续接上下文，而不是 `voice/` 自己维护一套 agent runtime

## 我的理解

`voice/` 最重要的价值，不是提供了一堆语音类型，而是把“文本 agent 已经能做的事”接进了一条足够明确的语音输入输出管线。

所以读这部分源码时，先盯住三层边界最有用：

- STT 负责把声音变成文本
- workflow 负责复用现有 agent runtime
- TTS 负责把文本重新包装成可播放的音频流

## 相关笔记

- [[OpenAI Agents SDK Voice 与 Realtime 的边界]]
- [[OpenAI Agents SDK Realtime 会话与事件流]]
- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK RunItem 与 stream event 数据结构]]
- [[OpenAI Agents SDK tracing 结构与 span 语义]]
- [[../../40-源码镜像/AI_Writer Vendor/OpenAI Agents SDK 目录到笔记映射]]
