---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
type: note
---

# OpenAI Agents SDK Sandbox Memory

## 这页的定位

Sandbox memory 不是普通聊天 `Session` 的替代品。

更准确地说：

- `Session` 存的是对话历史
- Sandbox memory 存的是从过去运行里提炼出来的工作经验

它们都在“保留过去”，但保留的对象完全不同。

## 1. 官方文档给出的核心定义

`docs/zh/sandbox/memory.md` 里讲得很清楚：

- 记忆独立于 SDK 的对话式 `Session`
- 它会把先前运行中的经验提炼为 sandbox 工作区中的文件
- 目标是降低智能体成本、用户成本和上下文成本

所以它更像：

“把工作经验沉淀成可供未来 sandbox 运行查阅的知识层。”

## 2. Memory 依赖的是工作区，而不是纯对话

这一点非常关键。

Sandbox memory 的产物默认写在工作区的 `memories/` 目录下，所以它的延续依赖于：

- 持续使用同一个实时 sandbox 会话
- 或从持久化的 session state / snapshot 中恢复

这意味着它不是靠数据库式消息存储在延续，而是和 sandbox workspace 生命周期绑定。

## 3. 读取记忆和生成记忆是两件事

文档和 capability 设计都说明，Memory 有两个面向：

- `read`
- `generate`

所以你可以配置成：

- 只读不生成
- 只生成不读取
- 读写都开启

这很适合不同角色的 sandbox agent：

- reviewer / verifier / checker 更适合只读
- 一次性工具 agent 可能不值得生成
- 主执行 agent 更适合读写都开

## 4. 读取记忆是渐进式披露

官方不是把所有历史直接塞进 prompt，而是分层读取：

1. 运行开始时，把简短的 `memory_summary.md` 注入开发者提示词
2. 如果看起来相关，再去查 `MEMORY.md`
3. 仍然不够时，再打开 `rollout_summaries/` 下对应 rollout 的摘要

这个设计很聪明，因为它避免了：

- 一上来把全部历史塞进上下文
- 让记忆反过来吞掉当前任务的 token 预算

所以 sandbox memory 本质上是“工作区知识检索”，不是“超长 prompt 回填”。

## 5. 生成记忆是两阶段流程

文档里已经给了很清晰的两阶段模型：

### Phase 1

对话提取。

它会处理某次 rollout 的累计对话文件，产出：

- rollout summary
- raw memory

### Phase 2

布局整合。

它会读取多个 rollout 产生的原始记忆，再整合成：

- `MEMORY.md`
- `memory_summary.md`

所以这套系统不是“每轮直接改最终记忆”，而是先提取，再整合。

## 6. 源码里谁在管这套流程

从 `src/agents/sandbox/memory/` 看，几个关键文件分工很清楚：

- `manager.py`
- `rollouts.py`
- `storage.py`
- `phase_one.py`
- `phase_two.py`
- `prompts.py`

我的理解是：

- `rollouts.py` 负责把运行结果写成 rollout 材料
- `phase_one.py` 负责从单次 rollout 中提取原始记忆
- `phase_two.py` 负责把多个 raw memories 整合成长期记忆
- `storage.py` 负责目录布局和文件读写
- `manager.py` 负责整个后台生成流程调度

## 7. `SandboxMemoryGenerationManager` 是主调度器

`manager.py` 里的 `SandboxMemoryGenerationManager` 很关键。

它的职责不是直接“生成记忆内容”，而是管理整个后台流程：

- 把 run result 变成 rollout payload
- 追加到 per-rollout JSONL 文件
- 在 sandbox session 结束时跑 phase 1
- 然后再统一跑一次 phase 2 consolidation

这个设计说明 memory 生成默认不是每次 turn 即时重写，而更像“在会话结束时集中整理”。

## 8. rollout 文件是中间事实层

`rollouts.py` 负责写 rollout 文件。

这一层的重要性在于：

- 它保留的是更接近真实运行过程的原始材料
- 然后 memory generation 再基于这些材料做提炼

所以可以把 sandbox memory 看成三层：

1. 运行事实
2. rollout 摘要与 raw memories
3. 最终 MEMORY / summary

## 9. `SandboxMemoryStorage` 体现了布局思路

`storage.py` 里能看到默认布局非常明确：

- `sessions/`
- `memories/MEMORY.md`
- `memories/memory_summary.md`
- `memories/raw_memories/`
- `memories/rollout_summaries/`
- `memories/skills/`

这意味着 memory 不是抽象对象，而是明确落在工作区目录树里。

这也解释了为什么它特别适合和 sandbox 一起用，而不是单独抽出来。

## 10. 多智能体隔离靠 layout，不靠 agent name

文档里这一点特别值得记：

- 记忆隔离是基于 `MemoryLayoutConfig`
- 不是基于 agent name

所以多个 agent 共享同一个 sandbox 时，如果不想共享记忆，关键不是改名字，而是给不同的：

- `memories_dir`
- `sessions_dir`

这会直接决定 raw memories、rollout summaries、MEMORY.md 是否共用。

## 11. 我现在对 sandbox memory 的一句话理解

它不是“自动帮你存聊天记录”，而是“把 sandbox 运行经验沉淀成工作区内可检索、可演化的知识文件系统”。

## 12. 和普通 Session 的边界

我会这样记：

### Session

- 关注消息历史
- 主要服务下一轮对话
- 偏 conversation continuity

### Sandbox Memory

- 关注经验提炼
- 主要服务未来工作
- 偏 workspace knowledge continuity

## 13. 后续最值得继续补的方向

- `phase_one.py` / `phase_two.py` 的提示词与产物格式
- `MemoryLayoutConfig` 在多 agent 场景下的实际用法
- `examples/sandbox/memory.py` 与 `memory_multi_agent_multiturn.py` 的案例拆解
