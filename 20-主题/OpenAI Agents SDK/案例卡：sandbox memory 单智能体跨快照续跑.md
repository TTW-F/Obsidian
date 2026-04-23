---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
  - 示例
type: note
source: E:\AI_Writer\vendor\openai-agents-python\examples\sandbox\memory.py
---

# 案例卡：sandbox memory 单智能体跨快照续跑

## 这个示例在演示什么

这个案例最核心的目标不是“怎么启用 Memory()”，而是演示：

- 第一次运行完成真实工作
- 关闭 sandbox session，触发 memory 生成
- 再从 snapshot 恢复一个新的 sandbox session
- 第二次运行在新的 session 中读取第一次留下的工作记忆

所以它验证的是：

“memory 能不能跨 snapshot 恢复后继续发挥作用。”

## 关键结构

这个例子用了四个关键点：

- `SandboxAgent(... capabilities=[Memory(), Filesystem(), Shell()])`
- `LocalSnapshotSpec(...)`
- 第一次 `Runner.run(...)`
- `client.resume(sandbox.state)` 后的第二次 `Runner.run(...)`

这四个点组合起来，才构成完整语义。

## 为什么它不是普通多轮

这个例子故意没有只在同一个 `async with sandbox` 里连续跑两轮。

它选择：

1. 第一轮结束并退出 sandbox session
2. 让 memory artifacts 在 session 关闭时生成
3. 再 resume 到新 session

所以它强调的是：

- 不是依赖“进程里还留着状态”
- 而是依赖 snapshot + memory artifacts 的组合

这和单纯的 in-memory 连续运行完全不同。

## manifest 设计也很有针对性

示例里的 manifest 很小，但足够形成一个真实问题场景：

- 一个有 bug 的 `report.py`
- 一个失败预期明确的 `pytest`

这样第一轮的任务是修 bug，第二轮的任务是补回归测试。

这种设计很适合验证 memory 是否真的记住了：

- 刚修过哪个 bug
- 第二轮应该围绕什么继续工作

## prompt 设计的意图

两个 prompt 分别是：

- 第一轮：修复 invoice total bug
- 第二轮：为前一个 bug 添加 regression test

这里第二轮 prompt 明显是“依赖上一轮成果”的。

如果没有 memory / snapshot 这条链，第二轮其实很难自然续上。

## 这个例子体现出的运行语义

我会把它总结成下面这条线：

1. 第一轮在 workspace 里做修改
2. sandbox session 关闭时，memory manager 生成记忆文件
3. workspace 通过 snapshot 保留下来
4. 新 sandbox session 从 snapshot 恢复
5. 第二轮通过 memory summary / MEMORY / rollout summaries 感知前情

所以这里不是 snapshot 或 memory 单独起作用，而是两者配合：

- snapshot 保工作现场
- memory 保工作经验

## 最值得观察的几个细节

### `Memory()` 用默认配置

这说明官方把它视作推荐默认，而不是只有专家才用的高级开关。

### `LocalSnapshotSpec`

说明示例重点就是“跨 session 续跑”。

### `_print_memory_tree()`

这个辅助函数非常有价值，因为它直接把示例产出的：

- `sessions/`
- `MEMORY.md`
- `memory_summary.md`
- `raw_memories/`
- `rollout_summaries/`

都打印出来，让你能把运行语义和落盘文件对上。

## 我从这个案例得到的实践结论

如果你要做：

- coding agent
- review agent
- 会在多个会话之间延续工作的 sandbox agent

那么最自然的组合不是只用 session，而是：

- sandbox
- snapshot
- memory

三者一起上。

## 这个案例适合放在学习路径的哪个位置

我会把它放在：

- 已经理解 `SandboxAgent`
- 已经理解 snapshot 基础概念
- 准备进入长任务 agent

之后再看。

因为它不是最小 hello world，而是“工作区连续性”示例。
