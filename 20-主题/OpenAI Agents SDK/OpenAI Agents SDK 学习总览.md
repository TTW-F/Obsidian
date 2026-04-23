---
tags:
  - 主题
  - OpenAI Agents SDK
  - AI Agent
type: topic
---

# OpenAI Agents SDK 学习总览

## 这是什么

这篇笔记是 OpenAI Agents SDK 主题区的总入口，用来先建立一张足够稳定的心智地图。

如果只先记一条主线，可以记成：`Agent` 定义角色与能力，`Runner` 启动执行，`run_internal/` 推进多轮流程，tools、handoffs、guardrails、sessions 和 tracing 在执行过程中持续介入。

## 为什么重要

- 这套 SDK 容易被误解成“帮你包装模型调用”的工具库，实际上它更像一个 agent 运行时
- 如果没有总览，后续读源码时会把很多横切能力看成零散模块
- 它适合先回答“这套仓库到底在做什么”，再把阅读顺序交给路线页、把运行样例交给示例页

## 这套 SDK 最值得先抓住的四层

### 1. 声明层

`Agent` 用来声明角色、工具、handoffs、guardrails 和输出方式。

### 2. 执行层

`Runner` 和 `run_internal/` 负责把一次任务拆成可持续推进的多轮执行过程。

### 3. 运行时能力层

tools、sessions / memory、tracing、guardrails 等模块解决的是执行过程中的实际控制与状态问题。

### 4. 扩展层

sandbox、MCP、model providers、realtime 和 voice 负责把 agent 能力延伸到更真实的工作区和外部系统。

## 建议阅读入口

- 如果我想知道先后顺序：[[OpenAI Agents SDK 研究路线]]
- 如果我想抓源码主线：[[OpenAI Agents SDK 执行主线与源码入口]]
- 如果我想理解整体 runtime：[[OpenAI Agents SDK 运行时编排]]
- 如果我想看扩展边界：[[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- 如果我想从 demo 和项目进入：[[OpenAI Agents SDK 示例与学习路径]]

## 最关键的仓库文档入口

- `docs/zh/index.md`
- `docs/zh/quickstart.md`
- `docs/zh/running_agents.md`
- `docs/zh/tools.md`
- `docs/zh/sandbox_agents.md`
- `docs/zh/tracing.md`
- `docs/zh/sessions/index.md`

## 最关键的源码入口

- `src/agents/__init__.py`
- `src/agents/agent.py`
- `src/agents/run.py`
- `src/agents/run_internal/`
- `src/agents/tool.py`
- `src/agents/memory/`
- `src/agents/tracing/`
- `src/agents/sandbox/`

## 易错点

- 容易把 `Runner` 当成一个简单启动器，而忽略它背后连接的运行时流程
- 容易把 sandbox、MCP、memory 等主题拆开记，结果缺少共同主线
- 容易把“学习顺序”和“能力总览”写在同一页里，最后入口页互相重复

## 我的理解

OpenAI Agents SDK 最核心的价值，不是“把模型调用写得更方便”，而是把多轮执行、工具协作、状态续跑和外部能力接入放进同一个运行时里。

先把这层理解稳住，后面无论是读源码、跑示例还是比较别的 agent 框架，都会更容易。

## 相关笔记

- [[../../10-领域/AI工程/OpenAI Agents SDK/OpenAI Agents SDK 总览]]
- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK 执行主线与源码入口]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK 示例与学习路径]]
