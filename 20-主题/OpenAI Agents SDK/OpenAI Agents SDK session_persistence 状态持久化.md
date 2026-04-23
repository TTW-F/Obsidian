---
tags:
  - 主题
  - OpenAI Agents SDK
  - session_persistence
  - 源码
type: note
---

# OpenAI Agents SDK session_persistence 状态持久化

## 这页的定位

`tool_execution.py` 负责把事情做完。

而 `session_persistence.py` 负责另一个同样关键的问题：

“这一轮做过的事，哪些要带到下一轮，哪些要写进 session，重试或恢复时又怎样避免重复。”

## 1. 这个文件的核心职责

从函数分布看，它主要负责四类事情：

- 把 session 历史和新输入合成为下一轮模型输入
- 把当前 turn 的新增结果写入 session
- 在 interruption / resume 之后修正 `RunState`
- 在重试、回滚和清理时避免重复积累历史

所以这层不只是“存储适配器”，而是运行时状态管理层。

## 2. `prepare_input_with_session` 是入口函数

这是我觉得最值得先记住的函数。

它做的事不是简单 `history + new_input`，而是：

1. 读取 session 历史
2. 规范化历史 item 和新输入 item
3. 可选地应用 `session_input_callback`
4. 区分“这次真的属于新 turn 的内容”和“只是历史重排出来的内容”
5. 做 normalize、drop orphan function calls、dedupe

最后返回两个值：

- 真正要送给模型的 prepared input
- 真正应该追加进 session 的新 turn items

这个设计很关键，因为它说明：

- “给模型看的输入”
- “需要持久化的新内容”

不是同一个概念。

## 3. 为什么这里要做引用匹配和频次匹配

源码注释写得很直白：如果 `session_input_callback` 会重排、过滤、复制历史项，就不能把 callback 返回结果整包再写回 session。

否则很容易把旧历史误当成新输入，再持久化一遍。

所以这里专门做了：

- reference map
- frequency map
- history / new items 分离

也就是说，这层在认真解决“历史重排不等于新增内容”这个问题。

## 4. `save_result_to_session` 是另一个主函数

如果说 `prepare_input_with_session` 负责“读和组装”，那 `save_result_to_session` 负责“写和防重”。

它主要处理：

- 只保存当前 turn 还没保存过的新增 items
- 把 `RunItem` 转成 session 可接受的 input item
- dedupe 当前输入与新增结果
- 计算 fingerprint，避免重试时重复写入
- 在需要时触发 responses compaction

这说明 session 持久化不是无脑 append，而是带状态计数和防重策略的增量保存。

## 5. 为什么 `run_state._current_turn_persisted_item_count` 很重要

这个内部计数是我很想记住的一个点。

它的作用是：

- 记录当前 turn 已经持久化了多少新增 items
- 在 streaming 重试或部分保存后，避免重复保存同一批内容

换句话说，这套 SDK 在设计上默认接受：

- 一轮可能分阶段持久化
- 一轮可能发生重试
- 一轮可能部分写成功后再继续

所以才需要这种细粒度计数。

## 6. `persist_session_items_for_guardrail_trip`

这个函数说明 guardrail tripwire 也不是“直接报错就完了”。

它还会尝试把必要输入先保存进 session。

这背后的运行时语义是：

- guardrail 中断了这轮处理
- 但输入本身可能仍然需要被会话层记住

所以 guardrail 与 session 也是联动的，不是完全独立。

## 7. interruption / resume 相关函数

这一层还有几组专门服务于恢复语义的函数：

- `session_items_for_turn`
- `resumed_turn_items`
- `update_run_state_after_resume`
- `save_resumed_turn_items`

这些函数组合起来说明：

- interruption 不是完全重新开一轮
- 恢复后需要明确哪些 generated items 继续保留
- 哪些 session items 需要补存
- `RunState` 的 original input、generated items、current step 都要一起修正

所以 resume 是“带状态续接”，不是“从头 replay”。

## 8. `rewind_session_items` 很值得重视

这是一个很工程化的函数。

它处理的是：

- 会话重试时，已经写进去的 session item 需要回滚
- 否则 session 里会积累重复输入

它会尝试：

- 用 fingerprint 匹配要回滚的 items
- 逐个 `pop_item`
- 必要时继续剥离 stray conversation items

这说明作者已经遇到过“部分写入成功，但上层又要重试”的真实问题。

## 9. `wait_for_session_cleanup`

这个函数进一步说明：

- 回滚也不是瞬时保证完成的
- 有时需要等待 session 真正清理干净

所以这层不只是在做纯逻辑变换，也在处理持久化后端的一致性等待问题。

## 10. 为什么这里大量使用 fingerprint

后半段这些 helper：

- `_ignore_ids_for_matching`
- `_sanitize_openai_conversation_item`
- `_fingerprint_or_repr`
- `_session_item_key`
- `_build_reference_map`
- `_build_frequency_map`

共同说明一个事实：

SDK 不能只靠 item 的对象身份或原始 ID 判断“是不是同一条内容”。

因为在不同 session backend、不同 conversation 模式下：

- item ID 可能不稳定
- item 会被转换
- item 可能经过 sanitize

所以最终要靠 fingerprint 和内容级匹配来防重与回滚。

## 11. 我现在对这一层的执行心智模型

我会把 `session_persistence.py` 记成下面这条链：

1. 读取 session 历史
2. 和新输入合成 prepared input
3. 区分“模型输入”和“本轮新增内容”
4. 每轮结束后只增量保存未持久化的新 items
5. 若发生 guardrail trip / retry / interruption / resume，再做补存、回滚或状态修正

## 12. 这一层和其它页面怎么配合看

可以这样串：

- [[OpenAI Agents SDK run_internal 执行链路]] 看总体分层
- [[OpenAI Agents SDK turn_resolution 决策流]] 看决策
- [[OpenAI Agents SDK tool_execution 工具执行流]] 看工具执行
- 这一页看状态如何在多轮之间持续

也就是：

- 前几页回答“这一轮发生了什么”
- 这一页回答“这些结果怎样延续到下一轮”

## 13. 下一步最适合继续补什么

- `prepare_input_with_session` 的 callback 语义和例子
- `save_result_to_session` 的 fingerprint / compaction 细拆
- interruption / resume 的完整状态流
