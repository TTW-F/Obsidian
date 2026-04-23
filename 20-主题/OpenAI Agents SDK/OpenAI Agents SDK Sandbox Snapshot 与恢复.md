---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Snapshot
type: note
---

# OpenAI Agents SDK Sandbox Snapshot 与恢复

## 这页的定位

如果说 sandbox memory 保存的是“经验”，那么 snapshot 保存的是“工作区状态本身”。

它们都能让未来运行延续过去，但延续的对象不同：

- memory 延续知识
- snapshot 延续文件系统状态

## 1. snapshot 的基本抽象

`src/agents/sandbox/snapshot.py` 里把 snapshot 抽象得很干净。

核心基类是 `SnapshotBase`，要求实现三个动作：

- `persist`
- `restore`
- `restorable`

这说明 snapshot 在设计上就是一个可插拔持久化后端。

## 2. 三种 snapshot 形态

目前源码里最明显的是三类：

- `LocalSnapshot`
- `RemoteSnapshot`
- `NoopSnapshot`

我会这样理解：

### `LocalSnapshot`

把 workspace archive 持久化到本地文件系统。

### `RemoteSnapshot`

通过依赖注入的远端 client 做 upload / download / exists。

### `NoopSnapshot`

明确表示“不做快照持久化”。

所以 snapshot 不是固定实现，而是一种协议加几个内建后端。

## 3. `SnapshotSpec` 和 `resolve_snapshot`

这层也很值得记。

源码区分了：

- 实际 snapshot 实例
- 用来构造实例的 `SnapshotSpec`

这让运行时可以先持有一个更轻的“规格”，等需要时再根据 `snapshot_id` 生成真正的 snapshot 对象。

`resolve_snapshot` 就是把这两层收口的地方。

## 4. snapshot 存的其实是 workspace archive

从 `snapshot_lifecycle.py` 看得很清楚：

- `persist_snapshot()` 会先调用 `session.persist_workspace()`
- 然后把得到的 archive 交给 snapshot 的 `persist()`

恢复时则反过来：

- 从 snapshot `restore()` 拿到 archive
- 再 `hydrate_workspace()`

所以 snapshot 保存的不是抽象状态对象，而是工作区归档。

## 5. 恢复时不是总要整仓回灌

这是我觉得特别重要的点。

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

## 6. 指纹不仅看文件，还看 manifest digest

源码里除了 fingerprint，还有：

- `resume_manifest_digest`
- `snapshot_fingerprint_version`

这意味着恢复判断不是只看文件内容是否一样，还会把 manifest 变化纳入考量。

这很合理，因为即使文件一样，mount 或 manifest 变化了，恢复语义也可能已经不同。

## 7. 恢复前会清理工作区，但会跳过某些路径

`snapshot_lifecycle.py` 里还有一条很重要的逻辑：

- `clear_workspace_root_on_resume`
- `workspace_resume_mount_skip_relpaths`
- `clear_workspace_dir_on_resume_pruned`

这说明恢复前不是粗暴 `rm -rf` 全部工作区。

它会保留某些与 mount 生命周期相关的路径，避免把不该动的挂载内容一起删掉。

所以 snapshot 恢复是“带挂载语义的清理和回灌”，不是简单覆盖。

## 8. 为什么 snapshot 和 session 要放在一起看

因为 snapshot 解决的是：

- 工作区文件状态如何延续

而 session 解决的是：

- 对话和运行状态如何延续

在真实的 sandbox 恢复里，这两者经常需要一起用。

例如：

- session 让 agent 知道之前聊到了哪里
- snapshot 让 agent 回到之前那个已经改过文件的 workspace

## 9. `snapshot_lifecycle.py` 是关键入口

如果后面要继续深读 sandbox resume，最值得优先盯的不是 `snapshot.py`，而是：

- `persist_snapshot`
- `restore_snapshot_into_workspace_on_resume`
- `can_skip_snapshot_restore_on_resume`
- `compute_and_cache_snapshot_fingerprint`
- `clear_workspace_root_on_resume`

因为这里才是真正把 snapshot 接进 sandbox session 生命周期的地方。

## 10. 和 sandbox memory 的边界

这两个概念很容易混。

我会这样强行区分：

### Sandbox Snapshot

- 保存 workspace 文件状态
- 面向恢复同一个工作现场
- 更像 checkpoint

### Sandbox Memory

- 保存经验总结和提炼知识
- 面向未来类似任务复用
- 更像 learned knowledge

## 11. 我现在对 snapshot 的一句话理解

它不是“把 agent 想法存下来”，而是“把 sandbox 工作现场打包成可恢复的检查点”。

## 12. 后续最值得继续补的方向

- `sandbox/session/sandbox_session.py` 里 snapshot 和 session state 的结合点
- 各类 sandbox backend 对 snapshot 的差异
- `examples/sandbox/*` 里 resume 场景的真实使用方式
