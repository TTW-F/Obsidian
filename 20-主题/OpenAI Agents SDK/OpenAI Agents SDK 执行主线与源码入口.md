---
tags:
  - 主题
  - OpenAI Agents SDK
  - 源码
  - Runner
type: note
---

# OpenAI Agents SDK 执行主线与源码入口

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 最值得先抓住的源码入口。

如果目标是从“知道这套 SDK 能做什么”走到“看懂它的执行骨架”，最稳的起点不是随机翻目录，而是先抓住 `Agent -> Runner -> run_internal` 这条主线。

## 为什么重要

- 入口选错了，很容易把时间花在局部 helper 上，却看不清运行骨架
- 这套 SDK 的关键不只是 API 暴露面，而是 `Runner.run()` 背后的多轮执行链
- 先抓源码入口，再进 `run_internal/`，更容易把后面的 tools、handoffs、sessions 和 tracing 理解成一条线

## 当前源码镜像位置

- 镜像总览：[[../../40-源码镜像/AI_Writer Vendor/AI_Writer vendor 源码镜像总览]]
- 代码根目录：`40-源码镜像/AI_Writer Vendor/openai-agents-python`

## 最先看的三个文件

### `src/agents/__init__.py`

这个文件最适合先拿来建立全局图。

从这里能直接看到 SDK 对外暴露的核心对象，例如：

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

如果还没想清楚这套 SDK 到底由哪些大块组成，先看这里最省力。

### `src/agents/agent.py`

这里的 `Agent` 更像配置对象，而不是执行器。

最值得记住的字段包括：

- `instructions`
- `prompt`
- `tools`
- `handoffs`
- `input_guardrails` / `output_guardrails`
- `model` / `model_settings`
- `output_type`

可以先把 `Agent` 理解成一个定义了角色、能力边界和输出规则的对象。

### `src/agents/run.py`

这里的 `Runner.run()` 才是真正的运行入口。

它把最核心的循环讲得很清楚：

1. 调用当前 agent
2. 如果拿到 final output，就结束
3. 如果发生 handoff，就切给下一个 agent
4. 否则执行工具，再进入下一轮

所以这套 SDK 的骨架不是 `Agent`，而是 `Runner` 背后的 loop。

## 真正的发动机在 `run_internal/`

当目标从“会用”变成“看懂实现”，就要进 `src/agents/run_internal/`。

这里最值得优先盯住的文件是：

- `run_loop.py`
- `run_steps.py`
- `turn_preparation.py`
- `turn_resolution.py`
- `tool_execution.py`
- `guardrails.py`
- `session_persistence.py`

可以先记住：

- `run.py` 更像总入口
- `run_internal/` 才是把执行过程真正拆开的地方

## 我现在会怎么读这条执行主线

1. 先看 `__init__.py`，建立全局对象地图
2. 再看 `agent.py`，确认 `Agent` 到底负责声明什么
3. 再看 `run.py`，确认 `Runner` 怎样启动执行
4. 然后进 `run_internal/`，理解运行时怎样把一轮执行拆成准备、决策、工具执行和状态延续

这条顺序的价值在于，它能先把“接口层”和“执行层”分开。

## 一个具体阅读场景怎么理解这页

如果我想回答“为什么一次 run 不是简单模型调用”，最好的顺序不是先看 examples，而是：

- 先看 `Agent` 能声明什么
- 再看 `Runner` 如何启动循环
- 最后进 `run_internal/` 看工具执行、handoff、guardrail 和 session persistence 怎样被接进来

这个场景能帮助我记住：源码入口页的作用，不是列文件名，而是帮我避免一开始就钻进局部实现。

## 最该记住的点

- `Agent` 不是主循环，它更像配置与能力声明对象
- `Runner.run()` 是总入口，但不是全部细节
- 真正的执行分层在 `run_internal/`
- 抓住 `Agent -> Runner -> run_internal`，后面的专题页会更容易对上位置

## 易错点

- 容易把 `Agent` 当成执行器，而忽略它更像配置对象
- 容易停在 `run.py`，却不继续往 `run_internal/` 深挖
- 容易随机翻 examples 或 helper，结果对运行骨架始终没有整体感

## 我的理解

理解这套 SDK 的第一步，不是去背 API 名字，而是先把 `Agent -> Runner -> run_internal` 这条主线抓稳。

只要这条线立住，后面的工具、handoff、guardrail、memory、sandbox 和 tracing 都会更容易落回同一张图里。

## 相关笔记

- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK 运行时编排]]
