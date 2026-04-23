---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Snapshot
type: note
---

# OpenAI Agents SDK Sandbox Snapshot 与恢复

## 这是什么

OpenAI Agents SDK 里的 sandbox snapshot，是把当前 sandbox 工作区打包成可恢复检查点的机制；恢复逻辑则负责在后续运行里把这份工作现场重新还原出来。

如果说 sandbox memory 保存的是经验和知识，那么 snapshot 保存的就是工作区状态本身。两者都在帮助后续运行延续过去，但延续的对象不同：

- memory 延续知识
- snapshot 延续文件系统状态

## 为什么重要

- 只有能恢复工作现场，agent 才真正具备“中断后继续工作”的能力
- snapshot 直接决定 sandbox 的恢复成本、重复 resume 的效率和文件状态一致性
- 理解这层之后，更容易区分 workspace 恢复、会话恢复和 memory 复用分别在解决什么问题

## snapshot 的基本抽象

`src/agents/sandbox/snapshot.py` 把 snapshot 设计成一个可插拔持久化后端。

核心基类 `SnapshotBase` 要求实现三个动作：

- `persist`
- `restore`
- `restorable`

这意味着 snapshot 的重点不是某一种固定实现，而是统一规定“如何保存、如何恢复、是否可恢复”。

## 常见的三种 snapshot 形态

源码里比较明显的是三类：

- `LocalSnapshot`
- `RemoteSnapshot`
- `NoopSnapshot`

它们分别对应：

- 本地文件系统持久化 workspace archive
- 通过远端 client 做 upload / download / exists
- 明确表示当前运行不做快照持久化

所以 snapshot 不是单一功能点，而是一套协议加若干内建后端。

## snapshot 保存的其实是什么

从 `snapshot_lifecycle.py` 看得很清楚：

- `persist_snapshot()` 会先调用 `session.persist_workspace()`
- 然后把得到的 archive 交给 snapshot 的 `persist()`

恢复时则反过来：

- 从 snapshot `restore()` 拿到 archive
- 再 `hydrate_workspace()`

所以 snapshot 保存的不是抽象状态对象，而是 workspace archive。

## 为什么恢复不一定要整仓回灌

`snapshot_lifecycle.py` 里专门做了指纹判断：

- `compute_and_cache_snapshot_fingerprint`
- `live_workspace_matches_snapshot_on_resume`
- `can_skip_snapshot_restore_on_resume`

也就是说，恢复逻辑不是一刀切地每次都重新解压整个 snapshot。

如果当前 live workspace 和 snapshot 指纹一致，就可以跳过恢复。

这说明作者很在意：

- 恢复性能
- 避免不必要的 workspace 重写
- 对长任务和重复 resume 的效率

## 为什么恢复前要带挂载语义地清理工作区

源码里还有一条很重要的逻辑：

- `clear_workspace_root_on_resume`
- `workspace_resume_mount_skip_relpaths`
- `clear_workspace_dir_on_resume_pruned`

这说明恢复前不是粗暴 `rm -rf` 全部工作区。

它会保留某些与 mount 生命周期相关的路径，避免把不该动的挂载内容一起删掉。

所以 snapshot 恢复是“带挂载语义的清理和回灌”，不是简单覆盖。

## snapshot 和 session 为什么要一起理解

snapshot 解决的是：

- 工作区文件状态如何延续

session 解决的是：

- 对话和运行状态如何延续

在真实的 sandbox 恢复里，这两者通常要一起工作：

- session 让 agent 知道之前聊到了哪里
- snapshot 让 agent 回到之前那个已经改过文件的 workspace

## 一个具体场景怎么理解这层

假设一个 sandbox 任务已经改了若干文件，还没彻底完成，中途需要暂停。

如果只有 session 恢复，没有 snapshot，那么 agent 可能记得“做到了哪”，却回不到原来的工作现场。
如果只有 snapshot，没有 session，它能看到文件状态，却不一定知道接下来该延续哪条任务主线。

这个场景能帮助我记住：snapshot 恢复的是工作现场，不是 agent 的想法。

## 和 sandbox memory 的边界

这两个概念很容易混，但职责不同：

- Sandbox Snapshot
  保存 workspace 文件状态，面向恢复同一个工作现场，更像 checkpoint
- Sandbox Memory
  保存经验总结和提炼知识，面向未来类似任务复用，更像 learned knowledge

## 易错点

- 容易把 snapshot 理解成“保存 agent 的想法”，其实它保存的是工作区现场
- 容易把恢复理解成每次都重新解压整个 workspace，忽略指纹判断和跳过恢复的优化
- 容易忽略 mount 语义，以为恢复前就是简单清空目录再覆盖
- 容易把 snapshot 和 session 混为一谈，前者恢复文件状态，后者恢复会话与运行状态

## 我的理解

snapshot 不是把 agent 的思路保存下来，而是把 sandbox 工作现场打包成可恢复检查点。

它真正让 agent 获得的能力，不是“记住说过什么”，而是“回到之前那个已经做了一半的工作环境里继续做”。

## 相关笔记

- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]
- [[OpenAI Agents SDK Sandbox Memory]]
- [[案例卡：sandbox memory 单智能体跨快照续跑]]
