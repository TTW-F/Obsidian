---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
  - 多智能体
  - 示例
type: note
source: D:\Git_Obsidian\Obsidian\40-源码镜像\AI_Writer Vendor\openai-agents-python\examples\sandbox\memory_multi_agent_multiturn.py
---

# 案例卡：sandbox memory 多智能体多轮隔离

## 这是什么

这是一个用同一个 sandbox workspace 承载多个 agent，但通过不同 `MemoryLayoutConfig` 把长期记忆分开的案例。

它回答的问题不是“memory 能不能工作”，而是“多个 agent 共用一个工作区时，怎样避免记忆彼此污染”。

## 为什么重要

- 它把 memory 的问题从“单 agent 续跑”推进到了“多角色边界设计”
- 真实系统里，共用 workspace 并不意味着应该共享长期记忆
- 这个案例把隔离策略直接落实到目录布局和产物层，而不是停留在抽象概念上

## 这个案例主要在验证什么

### 1. 共享 workspace 不等于共享记忆

示例里有两个角色：

- GTM analyst
- Engineering fixer

它们共享同一个 manifest 和同一个 sandbox workspace，但任务完全不同：

- GTM agent 看 `data/leads.csv` 做市场分析
- Engineering agent 修 `report.py` 的 invoice total bug

这正好构成了记忆隔离的典型需求。它们工作在同一个现场里，但长期记忆不应该混成一份。

### 2. 隔离靠 layout，不靠 agent name

这个案例最重要的设计点，是两个 agent 都显式配置了不同的：

- `memories_dir`
- `sessions_dir`

也就是：

- `memories/gtm` + `sessions/gtm`
- `memories/engineering` + `sessions/engineering`

这正好验证官方文档里那句话：记忆隔离靠 layout，不靠 agent name。

### 3. 多轮 session continuity 和多 agent isolation 可以同时存在

GTM agent 不是只跑一轮，而是用了同一个 `SQLiteSession(GTM_SESSION_ID)` 连续跑两轮：

1. 先做 segment 分析
2. 再基于前一轮分析写 outreach hypothesis

这说明：

- 多次 `Runner.run(...)`
- 共享同一个 SDK `Session`
- 再叠加相同 memory layout

就会形成同一个 memory conversation。

所以这个案例同时展示了：

- 多轮 conversation continuity
- 多 agent memory isolation

### 4. Engineering agent 的作用是证明隔离真的生效

Engineering agent 只跑一轮，但它很关键。

因为它证明了：

- 即使共用同一个 workspace
- 只要 memory layout 分开
- GTM 的分析记忆不会混进 engineering 的 bug-fix 记忆

这对真实工作流很重要，因为很多系统里不同角色会共享一个大工作区，但不应该共享同一份长期经验。

## 关键结构

这个案例里最值得盯的结构有三组：

- 同一个 sandbox workspace / manifest
- 两套不同的 `MemoryLayoutConfig`
- GTM 两轮 + Engineering 一轮的组合运行

它把这些因素放在一起，才真正形成了“共享工作区下的记忆分区”。

## `_print_tree()` 为什么有价值

这个例子最后会分别打印：

- `memories/gtm`
- `memories/engineering`
- `sessions/gtm`
- `sessions/engineering`

这一步很重要，因为它直接让你看到：

- 哪些文件被各自 agent 写下来了
- rollout / memory 目录是否真的分开

也就是把“布局隔离”从配置层验证到了产物层。

## 一个具体场景怎么理解这张案例卡

如果一个团队里同时有商业分析 agent 和工程修复 agent，它们可能都会用同一个工作区里的文件和产物，但这并不意味着前者的分析结论应该自动进入后者的长期记忆。

这个案例最值得学的地方，就是把这种“共享现场但不共享长期经验”的边界做成了目录布局，而不是停留在概念层。

## 最该记住的点

- 多 agent 共用同一个 workspace，并不意味着应该共用同一份长期记忆
- 决定记忆隔离的关键不是 agent name，而是 `MemoryLayoutConfig` 里的目录布局
- 多轮 session continuity 和多 agent memory isolation 可以同时存在，它们不是一回事
- 如果布局不分开，agent 的长期记忆很容易互相污染

## 易错点

- 容易把多 agent 隔离理解成“给 agent 换个名字”
- 容易把共用 workspace 误解成必须共享记忆
- 容易只看配置，不看产物层目录结构
- 容易把多轮 conversation continuity 和 memory isolation 混为一谈

## 我的理解

这个案例最接近真实系统设计问题的地方在于，它不再只是问“memory 好不好用”，而是在问“当多个角色开始协作时，长期记忆应该怎样切边界”。

OpenAI Agents SDK 给出的答案很明确：边界要落到 layout，而不是停留在命名层。

## 相关笔记

- [[案例卡：sandbox memory 单智能体跨快照续跑]]
- [[OpenAI Agents SDK Sandbox Memory]]
- [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
