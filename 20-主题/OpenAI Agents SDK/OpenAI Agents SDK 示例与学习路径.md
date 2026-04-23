---
tags:
  - 主题
  - OpenAI Agents SDK
  - 示例
type: note
---

# OpenAI Agents SDK 示例与学习路径

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 示例目录的导航方式，目标不是把所有 example 都记住，而是知道不同示例分别在帮助我理解哪一层能力。

如果已经对运行时主线有基本认识，这页可以用来决定下一步应该看最小闭环、常见 agent 模式，还是 sandbox 与完整工作流。

## 为什么重要

- 示例很多，如果没有分层，容易从头跑到尾却不知道每个例子在证明什么
- 把示例和运行时主题对应起来，能更快把“会跑 demo”变成“知道它为什么这样设计”
- 它也是从入门代码过渡到真实工程实践的桥梁

## 怎么选第一组示例

- 如果只想先跑通一次最小闭环，从 `examples/basic/` 开始
- 如果想看常见 agent 组织方式，先读 `agent_patterns`
- 如果想看更接近真实工程的接入方式，跳到 `memory / mcp / model_providers`
- 如果目标是工作区 agent 和长任务，重点看 `examples/sandbox/`

## 示例分组导航

### 1. 最小可运行闭环

先看 `examples/basic/`，重点关注：

- `hello_world.py`
- `tools.py`
- `stream_text.py`
- `tool_guardrails.py`
- `usage_tracking.py`

这一层的目标是跑通 `Agent + Runner + tool` 的最小闭环。

### 2. 常见 agent 模式

看 `examples/agent_patterns/README.md`，重点理解：

- deterministic flow
- routing
- agents as tools
- parallelization
- guardrails
- human in the loop

这一层最适合拿来和运行时概念做映射。

### 3. 状态、外部工具与 provider

关注：

- `examples/memory/`
- `examples/mcp/`
- `examples/model_providers/`

这组示例主要回答 demo 如何进入更接近真实工程的场景。

### 4. Sandbox

建议顺序：

1. `examples/sandbox/basic.py`
2. `examples/sandbox/sandbox_agent_with_tools.py`
3. `examples/sandbox/sandbox_agents_as_tools.py`
4. `examples/sandbox/memory.py`
5. `examples/sandbox/unix_local_runner.py`

这一层对应的是从“普通 agent”进入“工作区 agent”的关键跳转。

### 5. 完整工作流示例

最后可以看：

- `examples/research_bot/`
- `examples/financial_research_agent/`
- `examples/customer_service/main.py`

这里主要观察多角色拆分、工作流编排和最终输出组织。

## Sandbox 相关案例卡

如果已经理解 sandbox 的基础能力，可以接着看：

- [[案例卡：sandbox memory 单智能体跨快照续跑]]
- [[案例卡：sandbox memory 多智能体多轮隔离]]

## Sandbox 项目卡入口

如果目标不是理解单个 API，而是看较完整的 sandbox 工作流，可以直接跳到：

- [[项目卡：sandbox repo_code_review 工作流]]
- [[项目卡：sandbox vision_website_clone 工作流]]

可以这样分：

- `repo_code_review` 更偏代码审查型工作流
- `vision_website_clone` 更偏视觉复刻型工作流

## 适合怎么用这页

- 当我想找“最小闭环”示例时，从 `examples/basic/` 开始
- 当我想把运行时概念对应到常见套路时，看 `agent_patterns`
- 当我想研究工作区 agent 时，重点进 `examples/sandbox/`
- 当我想看更像正式应用的组织方式时，再进入完整工作流和项目卡

## 易错点

- 容易把示例导航页当成固定课程表，实际应根据当前问题跳读
- 容易只盯某个 demo 的业务外壳，不去对应底层运行时概念
- 容易在没理解基本闭环前就直接钻进 sandbox 或多代理示例

## 我的理解

示例最有价值的地方，不是替我背 API，而是帮我把抽象运行时概念落到一段能运行的代码上。

只要知道每组示例分别对应哪一层能力，我就更容易从“看过例子”进入“能拿它做判断和迁移”。

## 相关笔记

- [[OpenAI Agents SDK 学习总览]]
- [[OpenAI Agents SDK 研究路线]]
- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[案例卡：sandbox memory 单智能体跨快照续跑]]
- [[案例卡：sandbox memory 多智能体多轮隔离]]
