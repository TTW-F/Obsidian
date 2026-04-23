---
tags:
  - 主题
  - OpenAI Agents SDK
  - session_persistence
  - 源码
type: note
---

# OpenAI Agents SDK session_persistence 状态持久化

## 这是什么

这篇笔记记录 `session_persistence.py` 在运行时里真正承担的职责：一轮执行做过的事，哪些要带到下一轮，哪些要写进 session，以及重试或恢复时怎样避免历史越积越乱。

它不是单纯的“存储适配器”笔记，而更像运行时里的状态延续说明。

## 为什么重要

- 多轮 agent 执行最怕历史重复、恢复错位和状态断裂
- 这层既决定下一轮模型能看到什么，也决定 session 最终保存什么
- 如果低估这层，就会把很多重试、resume、compaction 问题误判成模型问题或工具问题

## 核心概念

这个文件可以先记成四类核心职责：

1. 读取 session 历史并与新输入组合
2. 区分“送给模型的输入”和“应该持久化的新内容”
3. 在 turn 结束后只增量保存本轮新增 items
4. 在 retry、interruption、resume 和回滚时修正状态

## 最值得先抓住的两个函数

### `prepare_input_with_session`

这是最推荐先看的入口。

它做的不是简单的 `history + new_input`，而是会：

1. 读取已有 session history
2. 规范化历史 item 和这轮新输入
3. 可选应用 `session_input_callback`
4. 区分“这轮真正新增的内容”和“只是从历史重排出来的内容”
5. 做 normalize、去掉 orphan function calls、dedupe

这里最值得记住的一点是：

“给模型看的输入”和“应该持久化的新内容”不是同一个概念。

### `save_result_to_session`

这个函数对应的是写入阶段。

它主要处理：

- 只保存当前 turn 还没保存过的新增 items
- 把 `RunItem` 转成 session 可接受的 input item
- dedupe 当前输入与新增结果
- 计算 fingerprint，避免重试时重复写入
- 必要时触发 responses compaction

所以这层不是无脑 append，而是在做增量保存和防重控制。

## 为什么这里一直在处理防重

原因很实际：

- 一轮可能会分阶段持久化
- 一轮可能会重试
- 一轮可能在部分写成功后继续推进
- 历史可能被 callback 重排或过滤

所以这里才会频繁依赖 reference map、frequency map、fingerprint 和当前 turn 已持久化计数。

## interruption / resume 为什么单独值得记

这层还有一组专门面向恢复语义的函数，例如：

- `session_items_for_turn`
- `resumed_turn_items`
- `update_run_state_after_resume`
- `save_resumed_turn_items`

这些函数说明了一件重要的事：interruption 不是“完全重开一轮”，resume 也不是“从头 replay 全部历史”。

更准确地说，它在努力保证恢复是“接着上一次已确认的状态继续走”。

## `rewind_session_items` 为什么有价值

这个函数很能体现工程现实。

它处理的是：如果某些 item 已经写进 session，但上层后来决定重试，要怎么把这些已保存内容安全回滚。

否则 session 很容易积累重复输入，下一轮上下文就会越来越脏。

## 一个具体场景

假设一轮里 agent 先执行工具、再被 guardrail 打断、随后用户批准继续执行。

这时运行时要同时回答：

- 历史里哪些内容已经算“确认写入”
- 哪些只是当前轮的临时结果
- 恢复时哪些 items 需要补回
- 哪些重复内容必须避免再次保存

这就是为什么 `session_persistence.py` 远不只是“历史存储接口”。

## 常见操作 / 用法

- 想先抓总入口，先读 `prepare_input_with_session` 和 `save_result_to_session`
- 想理解恢复语义，接着看 `session_items_for_turn`、`resumed_turn_items`、`update_run_state_after_resume`、`save_resumed_turn_items`
- 想理解为什么会有回滚，再看 `rewind_session_items`
- 想把这层放回整体运行链里理解，可以和 `turn_resolution.py`、`tool_execution.py` 对照着读

## 易错点

- 容易把 session 持久化理解成“把历史存起来”，忽略它同时在处理防重、恢复和回滚
- 容易把 prepared input 和 persisted items 当成同一份数据
- 容易把 retry / resume 问题归到别的模块，而忽略这里才是状态延续中心

## 我的理解

`session_persistence.py` 真正解决的是：一次 turn 的结果怎样稳定地接到下一轮，而不会在重试、恢复和压缩过程中越积越乱。

如果工具执行层决定了“做了什么”，那这一层决定的就是“这些事以后还能不能被正确记住和接上”。

## 相关笔记

- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK 运行时编排]]
