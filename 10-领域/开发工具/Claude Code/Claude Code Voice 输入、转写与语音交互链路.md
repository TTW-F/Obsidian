---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Voice
  - 语音
  - 源码分析
type: area
---

# Claude Code Voice 输入、转写与语音交互链路

## 这是什么

这篇笔记整理 Claude Code 语音输入不是“一个 `src/voice/` 目录”，而是一条跨 `voice/`、`hooks/`、`services/`、`keybindings/` 的完整链路。

我现在更倾向于把它理解成一套 hold-to-talk 输入子系统：前面用键位和状态判断决定能不能进入语音模式，中间负责录音与 WebSocket 转写，后面再把 interim / final transcript 安全地插回 prompt input。

## 为什么重要

- `src/voice/` 本身很薄，但它实际上卡在语音功能是否可见、是否可用的总开关上
- 真正复杂的部分散落在 `useVoiceIntegration.tsx`、`useVoice.ts`、`voiceStreamSTT.ts`，如果只盯目录名很容易低估这套系统
- 它也很能代表 Claude Code 的产品化风格: 输入层、远端服务、鉴权、GrowthBook、UI 反馈都被拆得比较克制

## 先记住这条主线

1. `voice/voiceModeEnabled.ts` 决定语音能力是否应该出现
2. `hooks/useVoiceEnabled.ts` 把用户设置、OAuth 鉴权和 GrowthBook kill-switch 合成 React 可用开关
3. `keybindings/defaultBindings.ts` 把 `voice:pushToTalk` 默认绑到 `space`
4. `hooks/useVoiceIntegration.tsx` 负责识别 hold-to-talk、吞掉按键泄漏、维护 interim transcript 插入位置
5. `hooks/useVoice.ts` 懒加载本地录音能力，并把录音会话和转写会话绑在一起
6. `services/voiceStreamSTT.ts` 用 OAuth 连 Anthropic `voice_stream` WebSocket，把音频帧变成 transcript
7. 最终 transcript 回写到输入框，继续走普通的 prompt 提交流程

## `src/voice/` 真正负责什么

`src/voice/voiceModeEnabled.ts` 只负责三层判断：

- `isVoiceGrowthBookEnabled()`
  - 看 `VOICE_MODE` feature 和 `tengu_amber_quartz_disabled` kill-switch
- `hasVoiceAuth()`
  - 要求当前是 Anthropic OAuth，而不是 API key、Bedrock、Vertex 这类接入
- `isVoiceModeEnabled()`
  - 把“有权限出现”与“当前已登录”合在一起

这层更像语音模式的准入门，而不是录音或转写本体。

## 可见性和可用性是分开的

这一点很值得记。

`useVoiceEnabled.ts` 不只是重复判断一次，而是把：

- 用户设置 `settings.voiceEnabled`
- `authVersion` 触发的鉴权状态变更
- GrowthBook kill-switch

组合成 React 渲染时可用的布尔值。

这里的关键点是 auth 检查会命中本地 token 读取，因此被 `useMemo` 包住；GrowthBook 查询便宜很多，所以保持每次 render 都能看到最新 kill-switch。

## 按键接入不在 voice 目录，而在 keybindings

默认键位在 `keybindings/defaultBindings.ts` 里：

- `Chat` context 下，`space -> voice:pushToTalk`

但这只是默认值，不是死绑。

配套还有三层约束：

- `keybindings/schema.ts`
  - 把 `voice:pushToTalk` 纳入可配置 action
- `keybindings/validate.ts`
  - 警告把它绑到裸字母时会在 warmup 阶段漏字
- `useVoiceIntegration.tsx`
  - 真正去解析当前 Chat context 里最后生效的单键绑定

所以语音激活键本质上是 keybinding 系统的一部分，而不是 voice 模块自己硬编码的按键监听。

## `useVoiceIntegration()` 负责把“按住说话”变成可用 UI

这是整条链里最产品化的一层。

我现在会先记住它做了四件事：

- 识别当前 `voice:pushToTalk` 绑定到底是什么键
- 区分 bare char 和 modifier combo
- 在 warmup/录音阶段清理误插入到输入框里的按键字符
- 维护 transcript 插入锚点，保证 interim / final 文本插在光标位置而不是覆盖整段输入

其中最关键的是 prefix/suffix 锚点：

- 录音开始时记住光标前后的文本
- interim transcript 始终插在两者之间
- 用户如果在处理中提交或改写了输入，就停止回填，避免把旧 transcript 再塞回去

这说明它不是简单“把语音结果 append 到输入框末尾”，而是专门考虑了交互竞争条件。

## `useVoice.ts` 才是录音与会话控制核心

`useVoice.ts` 把语音输入看成一个短生命周期会话：

- `idle`
- `recording`
- `processing`

它内部同时管理：

- 本地录音模块的懒加载
- release timeout 和 auto-repeat 检测
- focus mode / hold mode 区分
- accumulated transcript
- 失败重试与 silent-drop replay

这里有两个很重要的实现意图：

- 本地录音模块延迟加载，避免只是渲染 UI 就提前触发麦克风权限请求
- 语音会话结束时不是立刻读结果，而是等待 `finalize()` 和 WebSocket 关闭，确保最后一个 interim transcript 有机会提升为 final

## 转写传输层是 `voice_stream` WebSocket

`services/voiceStreamSTT.ts` 负责和 Anthropic 的语音转写接口对接。

最值得记住的是这些点：

- 走的是 `/api/ws/speech_to_text/voice_stream`
- 鉴权沿用 Claude Code 的 Anthropic OAuth token
- 连接的是 API listener，而不是直接打 `claude.ai`
- 客户端会发 `KeepAlive` 和 `CloseStream`
- 服务端返回 `TranscriptText`、`TranscriptEndpoint`、`TranscriptError`

`finalize()` 也不是单一结束动作，而是一个带兜底策略的等待过程：

- 正常等 `TranscriptEndpoint`
- 如果一直没数据，用 `no_data_timeout` 尽快结束
- WebSocket 卡住还有 `safety_timeout`

这一套设计明显是在对抗“音频已送出，但后端没有稳定回 transcript”的边缘情况。

## 语音词表增强是单独一层

`services/voiceKeyterms.ts` 会给 STT 补充 keyterms，包括：

- 全局编程词汇
- 当前项目名
- git branch 拆词
- recent files 里抽出来的文件名词

这不是模型推理，而是把当前会话语境压成一组关键词，交给 STT 引擎做识别增强。

我觉得这层很实用，因为它说明 Claude Code 不只是在“录音 -> 转文字”，而是在尽量让转出来的词更像开发语境。

## 这套链路的边界也很明确

语音不是任何环境都能开。

从相关实现看，它至少有这些边界：

- 必须是 Anthropic OAuth
- remote / homespace 这类没有本地音频设备的环境不支持
- modifier+space、chord 这类绑定并不适合 hold-to-talk
- 用户可以通过 keybindings 重绑激活键，但不是所有键都适合作为 hold key

所以这套设计默认前提是“本地终端 + 可用麦克风 + 可持续收到 key repeat”。

## 易错点

- 容易把 `src/voice/` 误看成完整语音实现，其实它只负责可见性和准入判断
- 容易忽略 `voice:pushToTalk` 是 keybindings 系统的一部分，而不是 voice 模块专属监听
- 容易把 transcript 回填理解成简单 append，实际上它有一整套 anchor 和 race guard
- 容易忽略 `voice_stream` 的 finalize、retry、silent-drop replay，结果低估这套链路的复杂度

## 我的理解

Claude Code 的语音实现不是“外挂一个语音按钮”，而是把语音当成 prompt input 的另一种入口。

它没有另起一套消息模型，而是尽量复用：

- 现有的 keybinding 解析
- 现有的输入框状态
- 现有的 OAuth 体系
- 现有的通知与设置机制

这也解释了为什么它的代码分散在多个目录里: 语音在这里不是独立产品，而是交互层的一种增量能力。

## 相关笔记

- [[Claude Code REPL、Ink 与交互层]]
- [[Claude Code Vim 模式与键位系统]]
- [[Claude Code 启动态配置注入与 bootstrap state]]
- [[Claude Code 文件系统与 Shell 安全模型]]
- [[../../40-源码镜像/AI_Writer Vendor/Claude Code 目录到笔记映射]]
