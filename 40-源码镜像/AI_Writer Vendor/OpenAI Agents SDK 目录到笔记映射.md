---
tags:
  - 源码镜像
  - OpenAI Agents SDK
  - 映射
type: note
---

# OpenAI Agents SDK 目录到笔记映射

## 这是什么

这页把 `40-源码镜像/AI_Writer Vendor/openai-agents-python/src/agents` 的主要目录，映射到已经沉淀好的 OpenAI Agents SDK 主题笔记。

它最适合在“我知道目录名，但不确定它属于哪条主线”时快速查表。

## 推荐先看哪几组

- 想抓执行骨架：先看 `run.py`、`run_internal/`、`models/`
- 想抓 agent 交接与工具：先看 `handoffs/`、`run_internal/`、`mcp/`
- 想抓 sandbox 长任务：先看 `sandbox/`、`memory/`、`extensions/`
- 想抓观测与调试：先看 `tracing/`、`util/`

## 目录到笔记映射

### 入口与对象层

- `__init__.py`、`agent.py`、`run.py`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 执行主线与源码入口]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 学习总览]]

### 运行时主线

- `run_internal/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK run_internal 执行链路]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK turn_resolution 决策流]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tool_execution 工具执行流]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK session_persistence 状态持久化]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK approvals、interruptions 与恢复语义]]

### 交接、工具与协议转换

- `handoffs/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK handoff 交接语义与输入迁移]]

- `mcp/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP 连接管理与调用链]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP Transport 与 Session 建立]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP 请求串行化与共享 Session 语义]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK MCP Message Handler 与 Session 消息流]]

- `models/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 模型抽象层与 Provider 路由]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 默认模型与 ModelSettings 合并规则]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tools 到 Responses payload 的转换细节]]

### Sandbox 与长期任务

- `sandbox/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Manifest、AGENTS.md 与产物契约]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Snapshot 与恢复]]

- `memory/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Memory]]
  - [[../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 单智能体跨快照续跑]]
  - [[../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 多智能体多轮隔离]]

- `extensions/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 运行时编排]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox、MCP 与扩展生态]]

### 流式事件与可观测性

- `tracing/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK tracing 结构与 span 语义]]

- `util/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK RunItem 与 stream event 数据结构]]

### 其他能力面

- `realtime/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Realtime 会话与事件流]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Voice 与 Realtime 的边界]]

- `voice/`
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Voice 输入输出管线]]
  - [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Voice 与 Realtime 的边界]]

## examples 到案例卡的回链

- `examples/sandbox/memory.py`
  - [[../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 单智能体跨快照续跑]]

- `examples/sandbox/memory_multi_agent_multiturn.py`
  - [[../../20-主题/OpenAI Agents SDK/案例卡：sandbox memory 多智能体多轮隔离]]

- `examples/sandbox/tutorials/repo_code_review`
  - [[../../20-主题/OpenAI Agents SDK/项目卡：sandbox repo_code_review 工作流]]

- `examples/sandbox/tutorials/vision_website_clone`
  - [[../../20-主题/OpenAI Agents SDK/项目卡：sandbox vision_website_clone 工作流]]

## 现在最值得继续补的缺口

- `mcp/` 的主干已经补到连接、transport、请求串行化和 message handler，但 resources / prompts 与更高层 Agent 行为的对接还可以继续细化
- `tracing/` 目前已经有结构页，后面还能继续补 span 与具体运行阶段的一一对应关系

## 相关笔记

- [[AI_Writer vendor 源码镜像总览]]
- [[../../10-领域/AI工程/OpenAI Agents SDK/OpenAI Agents SDK 总览]]
- [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 研究路线]]
