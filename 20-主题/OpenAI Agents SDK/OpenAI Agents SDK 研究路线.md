---
tags:
  - 主题
  - OpenAI Agents SDK
  - 研究路线
type: topic
---

# OpenAI Agents SDK 研究路线

## 这篇笔记要解决什么

这篇不讲某个单点模块，而是记录我研究 OpenAI Agents SDK 时的观察顺序。

## 我会按什么顺序研究

### 1. 先看公共入口

先看：

- `src/agents/__init__.py`
- `src/agents/agent.py`
- `src/agents/run.py`

目的是先搞清楚：

- SDK 对外暴露了哪些核心对象
- `Agent` 负责声明什么
- `Runner` 负责执行什么

### 2. 再看 `run_internal/`

这是执行引擎真正展开的地方。

我会重点看：

- `run_loop.py`
- `run_steps.py`
- `turn_preparation.py`
- `turn_resolution.py`
- `tool_execution.py`
- `session_persistence.py`

### 3. 再看运行时横切层

也就是：

- tools
- handoffs
- guardrails
- sessions / memory
- tracing

这一层用来回答：一次 run 为什么不仅仅是“调一次模型”。

### 4. 再看扩展层

包括：

- sandbox
- mcp
- model providers
- realtime / voice

### 5. 最后看 examples 和 docs

这一步不是入门，而是验证前面理解是否能映射回真实示例。

## 为什么按这个顺序

因为如果一开始就沉到 examples，很容易会用，但抓不住 runtime 骨架。

先看公开入口和执行链，再回头看示例，理解会更稳。

## 我当前的研究锚点

- [[../../10-领域/AI工程/OpenAI Agents SDK/OpenAI Agents SDK 总览]]
- [[OpenAI Agents SDK 学习总览]]
- [[OpenAI Agents SDK 执行主线与源码入口]]

## 对应主题页

- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK 示例与学习路径]]

## 我的理解

研究这套 SDK 最怕“概念都认识，但不知道应该先看哪层”。

一旦研究顺序固定下来，后面无论看 docs、examples 还是源码细节，都更容易落到同一张心智地图里。
