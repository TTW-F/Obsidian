---
tags:
  - 主题
  - OpenAI Agents SDK
  - 源码
  - Runner
type: note
---

# OpenAI Agents SDK 执行主线与源码入口

## 这篇笔记要解决什么

这篇主要回答：

如果我想从“知道这套 SDK 是干什么的”走到“真正读懂它的执行骨架”，最应该先看哪些源码入口。

## 我研究这部分时最关心什么

- 公共 API 如何暴露整体能力
- `Agent` 和 `Runner` 的职责如何分开
- `run_internal/` 为什么是理解执行链的关键入口

## 公共 API 总地图

`src/agents/__init__.py` 基本可以当成这套 SDK 的“公开能力索引”。

从这里能直接看出它对外暴露的核心对象：

- `Agent`
- `Runner`
- `Tool`
- `Handoff`
- `Guardrail`
- `Session`
- `Tracing`
- `Model`
- `Sandbox`
- `Realtime`
- `Voice`

如果要快速建立全局视图，先读这个文件最省力。

## Agent 是声明式配置中心

`src/agents/agent.py` 里的 `Agent` 更像配置对象，而不是执行器。

重点字段包括：

- `instructions`
- `prompt`
- `tools`
- `handoffs`
- `input_guardrails` / `output_guardrails`
- `model` / `model_settings`
- `output_type`

所以可以把 `Agent` 理解成：

“一个定义了能力边界、行为规则和输出格式的角色对象”。

## Runner 是真正的运行入口

`src/agents/run.py` 里的 `Runner.run()` 是主入口。

这个文件本身已经把最重要的运行循环写出来了：

1. 调用当前 agent
2. 如果得到 final output，就结束
3. 如果发生 handoff，就切换到新 agent
4. 否则执行工具，再进入下一轮

也就是说，SDK 的骨架不是 `Agent`，而是 `Runner` 背后的 loop。

## 真正的发动机在 `run_internal/`

当你想从“会用”进入“看懂实现”，就要进 `src/agents/run_internal/`。

目前最值得优先盯住的文件：

- `run_loop.py`
- `run_steps.py`
- `turn_preparation.py`
- `turn_resolution.py`
- `tool_execution.py`
- `guardrails.py`
- `session_persistence.py`

我当前的理解是：

- `run.py` 像总调度入口
- `run_internal/` 才是把每一步拆开的运行细节层

## 推荐源码阅读顺序

1. `src/agents/__init__.py`
2. `src/agents/agent.py`
3. `src/agents/run.py`
4. `src/agents/run_internal/run_steps.py`
5. `src/agents/run_internal/turn_preparation.py`
6. `src/agents/run_internal/turn_resolution.py`
7. `src/agents/run_internal/tool_execution.py`
8. `src/agents/run_internal/session_persistence.py`
9. `src/agents/run_internal/run_loop.py`

## 我现在抓到的执行链路

- `Runner.run()` 接收 agent、input、context、run_config、session 等参数
- 准备 tracing、conversation、session 和 runtime state
- 每轮里解析模型响应
- 决定下一步是 final output、handoff、tool run 还是 interruption
- 执行 guardrail、工具和持久化
- 继续下一轮或结束

## 我的理解

理解这套 SDK 的第一步，不是记 API 名字，而是先把 `Agent -> Runner -> run_internal` 这条主线抓稳。

## 相关笔记

- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK run_internal 执行链路]]
