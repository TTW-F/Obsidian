---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Memory
  - 示例
type: note
source: D:\Git_Obsidian\Obsidian\40-源码镜像\AI_Writer Vendor\openai-agents-python\examples\sandbox\memory.py
---

# 案例卡：sandbox memory 单智能体跨快照续跑

## 这是什么

这是一个用 `SandboxAgent`、`Memory()` 和 `LocalSnapshotSpec` 组合出来的案例，用来验证单智能体能否在 sandbox session 结束后，依然通过 snapshot 恢复工作现场，并在新 session 中继续利用上一轮形成的记忆。

它不是在讲“如何打开 memory 功能”，而是在讲 memory 和 snapshot 组合之后，跨 session 续跑是否真的成立。

## 为什么重要

- 它把 `memory` 和 `snapshot` 的职责拆开验证了一次
- 两者组合后，任务连续性不必依赖同一个长活 session
- 这很接近真实的 agent 工作方式：先完成一轮，再在新的运行环境里接着处理后续任务

## 这个案例主要在验证什么

### 1. 它验证的不是普通多轮对话

这个案例没有把两轮任务放在同一个存活中的 sandbox session 里连续完成，而是刻意经历了下面这条链路：

1. 第一轮运行完成真实任务
2. 关闭当前 sandbox session
3. 在 session 关闭后生成 memory artifacts
4. 通过 snapshot 恢复新的 sandbox session
5. 在新 session 中继续第二轮任务

所以它要验证的是：任务连续性是否还能在“旧 session 已经结束”的前提下成立。

### 2. 它验证 memory 和 snapshot 的分工

这个案例最有价值的地方，不是展示某个 API 调用，而是把两类连续性拆开：

- `snapshot` 保留文件、环境和工作现场
- `memory` 保留任务背景、前一轮结果和后续可复用的摘要

如果只有 snapshot，没有 memory，第二轮虽然能看到文件现场，但不一定能自然理解“上一轮为什么这样改”。如果只有 memory，没有 snapshot，又缺少具体工作现场。

这个案例验证的是两者配合后的完整续跑语义。

### 3. 它验证第二轮 prompt 是否真的依赖前一轮成果

案例中的两轮任务是连着的：

- 第一轮修复 invoice total bug
- 第二轮为这个 bug 增加 regression test

第二轮不是新任务，而是建立在第一轮成果之上的延续任务。也正因为这样，这个案例才能真正验证 memory 是否让系统记住了“刚刚修过什么、下一步应该做什么”。

## 关键结构

这个案例的运行语义主要由四个部分构成：

- `SandboxAgent(... capabilities=[Memory(), Filesystem(), Shell()])`
- `LocalSnapshotSpec(...)`
- 第一次 `Runner.run(...)`
- `client.resume(sandbox.state)` 之后的第二次 `Runner.run(...)`

这四个点组合起来，才构成“跨快照续跑”的完整含义。

## `_print_memory_tree()` 为什么有价值

这个例子里 `_print_memory_tree()` 很有价值，因为它能把两件事直接对上：

- 运行语义：memory 在这次案例里到底承担了什么
- 实际产物：memory 文件最终落成了什么目录和内容

这会让“跨 session 续跑”不只停留在 prompt 结果层，而能落到工作区产物层。

## 一个具体场景怎么理解这张案例卡

如果一个 agent 在第一轮已经修完 bug，第二轮需要基于这个结果补测试，那么真正有价值的并不是“记住上一段聊天”，而是同时保留：

- 第一轮改过的工作现场
- 第一轮沉淀出的任务记忆

这个案例最值得学的，就是它把这两类连续性拆开验证了。

## 最该记住的点

- 这个案例验证的是“memory 能不能跨 snapshot 恢复后继续发挥作用”，不是单纯演示 `Memory()` 怎么启用
- `snapshot` 保工作现场，`memory` 保工作记忆；两者配合才构成真正的跨 session 续跑
- 只在同一个长活 session 里连续运行，不足以说明 memory 机制已经被验证
- `_print_memory_tree()` 能把运行语义和 memory 文件实际产物对应起来

## 易错点

- 容易把这个案例理解成普通多轮对话示例
- 容易把 snapshot 当成全部连续性来源，而忽略 memory 更偏任务背景和经验摘要
- 容易只盯着 API 表面调用，看漏“关闭 session 后再恢复”的运行语义
- 容易忽略第二轮 prompt 的设计，它之所以有验证价值，就是因为明显依赖第一轮成果

## 我的理解

这个案例最有价值的地方，是它把“经验延续”和“工作现场延续”拆成了两条线，再验证它们能不能在新的 sandbox session 里重新合起来。

也正因为这样，它比单纯演示 `Memory()` 更接近真实的长期任务语义。

## 相关笔记

- [[OpenAI Agents SDK Sandbox Memory]]
- [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[案例卡：sandbox memory 多智能体多轮隔离]]
