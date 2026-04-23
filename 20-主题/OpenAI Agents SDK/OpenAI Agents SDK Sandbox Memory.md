---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
type: note
---

# OpenAI Agents SDK Sandbox Memory

## 这是什么

`Sandbox memory` 是 OpenAI Agents SDK 在 sandbox 场景里提供的一层“工作经验记忆机制”。

它不是普通聊天 `Session` 的替代品，更像是把一次次 sandbox 运行中沉淀出来的经验，整理成工作区里可继续读取的知识文件。

我现在会强行这样区分：

- `Session` 存的是对话历史
- `Sandbox memory` 存的是从过去运行里提炼出来的工作经验

## 为什么重要

- 长任务 agent 往往不只需要“记得聊到哪”，还需要“记得之前做过什么、踩过什么坑、哪些信息值得以后复用”
- 如果把所有过去经历都塞回 prompt，成本会越来越高，结构也会越来越乱
- `Sandbox memory` 提供的是另一条路：把经验沉淀到工作区，再按需要渐进式读取

## 它和 Session 的边界

这两个概念都在“保留过去”，但保留对象完全不同：

### Session

- 关注消息历史
- 主要服务下一轮对话
- 更偏 conversation continuity

### Sandbox Memory

- 关注经验提炼
- 主要服务未来工作
- 更偏 workspace knowledge continuity

所以 sandbox memory 不是“自动帮你存聊天记录”，而是“把工作经验沉淀成工作区里的知识层”。

## 为什么它依赖工作区，而不是纯对话

Sandbox memory 的产物默认写在工作区的 `memories/` 目录下，所以它的延续依赖于：

- 持续使用同一个实时 sandbox 会话
- 或从持久化的 session state / snapshot 中恢复

这意味着它不是靠数据库式消息存储在延续，而是和 sandbox workspace 生命周期绑定。

## 读取记忆和生成记忆是两件事

文档和 capability 设计都说明，Memory 至少有两个面向：

- `read`
- `generate`

所以你可以把它配置成：

- 只读不生成
- 只生成不读取
- 读写都开启

这很适合不同角色的 sandbox agent：

- reviewer / verifier / checker 更适合只读
- 一次性工具 agent 可能不值得生成
- 主执行 agent 更适合读写都开

## 读取记忆为什么是渐进式披露

官方不是把所有历史直接塞进 prompt，而是分层读取：

1. 运行开始时，把简短的 `memory_summary.md` 注入开发者提示词
2. 如果看起来相关，再去查 `MEMORY.md`
3. 仍然不够时，再打开 `rollout_summaries/` 下对应 rollout 的摘要

这个设计的价值在于：

- 避免一上来把全部历史塞进上下文
- 避免记忆反过来吞掉当前任务的 token 预算
- 让 memory 更像工作区知识检索，而不是超长 prompt 回填

## 生成记忆为什么是两阶段流程

文档里给出的模型很清楚：

### Phase 1

对话提取。它会处理某次 rollout 的累计对话文件，产出：

- rollout summary
- raw memory

### Phase 2

布局整合。它会读取多个 rollout 产生的原始记忆，再整合成：

- `MEMORY.md`
- `memory_summary.md`

所以这套系统不是“每轮直接改最终记忆”，而是先提取，再整合。

## 这套流程在源码里怎样落地

从 `src/agents/sandbox/memory/` 看，几个关键文件分工比较清楚：

- `rollouts.py` 负责把运行结果写成 rollout 材料
- `phase_one.py` 负责从单次 rollout 中提取原始记忆
- `phase_two.py` 负责把多个 raw memories 整合成长期记忆
- `storage.py` 负责目录布局和文件读写
- `manager.py` 负责整个后台生成流程调度

## 一个具体场景怎么理解这层

假设一个 sandbox agent 连续修过几次同类问题。

如果没有 memory，它只能依赖当前对话上下文去记住“上次怎么做的”。
如果只有 snapshot，它能恢复工作现场，却未必知道“为什么之前要这样做”。

而 sandbox memory 的价值就在于：把这些经验提炼成后续可重新读取的知识层。

这正好说明了它和 session、snapshot 的边界：

- session 保留对话连续性
- snapshot 保留工作现场
- memory 保留可复用经验

## 多智能体隔离为什么靠 layout，不靠 agent name

文档里这一点特别值得记：

- 记忆隔离是基于 `MemoryLayoutConfig`
- 不是基于 agent name

所以多个 agent 共享同一个 sandbox 时，如果不想共享记忆，关键不是改名字，而是给不同的：

- `memories_dir`
- `sessions_dir`

这会直接决定 raw memories、rollout summaries、`MEMORY.md` 是否共用。

## 易错点

- 容易把 sandbox memory 当成普通 session 的替代品
- 容易以为它会把所有历史直接塞进 prompt，而忽略它的重点恰恰是渐进式读取
- 容易忽视工作区生命周期，memory 文件落在 workspace 里，所以 snapshot、resume、session 生命周期都会影响它怎么延续
- 容易把多 agent 的记忆隔离理解成“换个 agent 名字”

## 我的理解

Sandbox memory 最有价值的地方，是它把“经验延续”从对话历史里拆了出来。

这样 agent 不必永远背着一长串聊天记录，也能在新的 sandbox 会话里继续利用过去工作中沉淀下来的知识。

## 相关笔记

- [[OpenAI Agents SDK 学习总览]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[案例卡：sandbox memory 单智能体跨快照续跑]]
- [[案例卡：sandbox memory 多智能体多轮隔离]]
