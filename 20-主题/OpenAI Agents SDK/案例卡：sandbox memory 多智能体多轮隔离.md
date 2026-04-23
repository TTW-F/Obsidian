---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
  - 多智能体
  - 示例
type: note
source: E:\AI_Writer\vendor\openai-agents-python\examples\sandbox\memory_multi_agent_multiturn.py
---

# 案例卡：sandbox memory 多智能体多轮隔离

## 这个示例在演示什么

这个案例的重点不是单 agent 跨快照延续，而是：

- 同一个 sandbox workspace
- 两类不同 agent
- 各自多轮或单轮运行
- 通过不同 `MemoryLayoutConfig` 做记忆隔离

所以它回答的问题是：

“多个 agent 共用一个工作区时，如何避免记忆相互污染。”

## 场景拆分

示例里有两个角色：

- GTM analyst
- Engineering fixer

它们共享同一个 manifest 和同一个 sandbox workspace，但任务完全不同：

- GTM agent 看 `data/leads.csv` 做市场分析
- Engineering agent 修 `report.py` 的 invoice total bug

这正好构成了记忆隔离的典型需求。

## 为什么这里只靠 agent name 不够

这个例子最重要的设计点，就是两个 agent 都显式配置了不同的：

- `memories_dir`
- `sessions_dir`

也就是：

- `memories/gtm` + `sessions/gtm`
- `memories/engineering` + `sessions/engineering`

这正好验证官方文档里那句话：

记忆隔离靠 layout，不靠 agent name。

## 这个例子还顺手演示了多轮 memory conversation

GTM agent 不是只跑一轮，而是用了同一个 `SQLiteSession(GTM_SESSION_ID)` 连续跑两轮：

1. 先做 segment 分析
2. 再基于前一轮分析写 outreach hypothesis

这表示：

- 多次 `Runner.run(...)`
- 共享同一个 SDK `Session`
- 再叠加相同 memory layout

就会形成同一个 memory conversation。

所以这个案例同时展示了：

- 多轮 conversation continuity
- 多 agent memory isolation

## engineering agent 的作用

Engineering agent 只跑一轮，但它很关键。

因为它证明了：

- 即使共用同一个 workspace
- 只要 memory layout 分开
- GTM 的分析记忆不会混进 engineering 的 bug-fix 记忆

这对真实工作流很重要。

很多真实系统里：

- 商业分析 agent
- 编码 agent
- 审查 agent
- verifier agent

都可能共用一个大工作区，但它们不应该共享同一份长期记忆。

## 为什么这个例子比单智能体案例更像真实系统

单智能体案例更像“记忆能不能工作”。

而这个案例更像“真实工作流里怎么设计记忆边界”。

因为它已经开始处理：

- 多角色
- 多轮
- 同一 workspace
- 不同记忆布局

这比单纯开 `Memory()` 更接近生产设计问题。

## `_print_tree()` 的价值

这个例子最后会分别打印：

- `memories/gtm`
- `memories/engineering`
- `sessions/gtm`
- `sessions/engineering`

这一步非常好，因为它直接让你看到：

- 哪些文件被各自 agent 写下来了
- rollout / memory 目录是否真的分开

也就是把“布局隔离”从配置层验证到了产物层。

## 我从这个案例得到的实践结论

如果未来你要在一个 sandbox workspace 里放多个 agent，先问的不是：

- 这些 agent 叫什么

而是：

- 它们该不该共享长期记忆
- 如果不该，共享哪些目录，隔离哪些目录

而 OpenAI Agents Python 给出的正统答案就是：

- 用 `MemoryLayoutConfig` 显式分区

## 这个案例最适合什么读者

它最适合：

- 已经懂 `SandboxAgent`
- 已经懂 `Memory()`
- 开始思考多 agent 工程结构

的人看。

如果还没理解单 agent memory，建议先看 [[案例卡：sandbox memory 单智能体跨快照续跑]]。
