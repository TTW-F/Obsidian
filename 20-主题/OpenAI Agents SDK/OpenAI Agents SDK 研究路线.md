---
tags:
  - 主题
  - OpenAI Agents SDK
  - 研究路线
type: topic
---

# OpenAI Agents SDK 研究路线

## 这是什么

这篇笔记把整组 OpenAI Agents SDK 笔记整理成一条可执行的阅读路径。

如果我一时不知道下一篇该看什么，就按这条路线往下走。

## 我现在推荐的总顺序

我会按这五段走：

1. 先建立总心智模型
2. 再吃透运行时主链路
3. 再理解横切能力与扩展边界
4. 再进入 sandbox 长任务能力
5. 最后用案例卡和项目卡把理解落地

## 第一阶段：先建立总心智模型

先看：

- [[OpenAI Agents SDK 学习总览]]
- [[OpenAI Agents SDK 执行主线与源码入口]]

这一阶段只需要先抓住三件事：

- `Agent` 是声明式配置中心
- `Runner` 是执行入口
- 整体主线是 `Agent -> Runner -> run_internal -> tools / handoffs / guardrails / sessions / tracing`

如果这一步没稳住，后面看任何示例都容易变成“会用，但抓不住主线”。

## 第二阶段：吃透运行时主链路

接着看：

- [[OpenAI Agents SDK run_internal 执行链路]]
- [[OpenAI Agents SDK turn_resolution 决策流]]
- [[OpenAI Agents SDK tool_execution 工具执行流]]
- [[OpenAI Agents SDK session_persistence 状态持久化]]

这一阶段要回答的是：

- 一次 run 在内部到底如何被拆层
- 模型 response 如何变成下一步动作
- 工具执行为什么会牵涉 approval、guardrail、tracing
- session 为什么不是最后顺手存一下历史，而是运行时主线的一部分

这一步做完之后，你对这套 SDK 的理解会从“功能列表”升级成“执行链”。

## 第三阶段：理解横切能力与扩展边界

再看：

- [[OpenAI Agents SDK 运行时编排]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]

这一阶段重点不是继续往函数级细拆，而是拉开边界：

- tools、handoffs、guardrails 分别解决什么问题
- sessions、tracing 为什么是横切层
- sandbox、mcp、provider、realtime、voice 怎样接进整体架构

这一步相当于把主运行时骨架和外围能力真正接上。

## 第四阶段：进入 sandbox 长任务能力

到这里再进入 sandbox，会更稳。建议按这组顺序看：

- [[OpenAI Agents SDK Sandbox Memory]]
- [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[案例卡：sandbox memory 单智能体跨快照续跑]]
- [[案例卡：sandbox memory 多智能体多轮隔离]]

这一阶段最关键的是区分三件事：

- `Session`：对话和运行状态延续
- Sandbox memory：工作经验提炼
- Snapshot：工作区现场恢复

这也是 OpenAI Agents SDK 和一般 agent runtime 真正拉开差距的地方。

## 第五阶段：回到示例与项目卡落地

这时再看：

- [[OpenAI Agents SDK 示例与学习路径]]
- [[项目卡：sandbox repo_code_review 工作流]]
- [[项目卡：sandbox vision_website_clone 工作流]]

这一阶段的目标，是把前面的理解落到两种工作流范式上：

- 代码/仓库型 sandbox 工作流
- 视觉/界面型 sandbox 工作流

## 如果只想走最短路线

如果以后时间很少，我会只按这 10 页走：

1. [[OpenAI Agents SDK 学习总览]]
2. [[OpenAI Agents SDK 执行主线与源码入口]]
3. [[OpenAI Agents SDK run_internal 执行链路]]
4. [[OpenAI Agents SDK turn_resolution 决策流]]
5. [[OpenAI Agents SDK tool_execution 工具执行流]]
6. [[OpenAI Agents SDK session_persistence 状态持久化]]
7. [[OpenAI Agents SDK Sandbox Memory]]
8. [[OpenAI Agents SDK Sandbox Snapshot 与恢复]]
9. [[案例卡：sandbox memory 单智能体跨快照续跑]]
10. [[项目卡：sandbox repo_code_review 工作流]]

## 怎么判断自己已经抓住主线

- 能说清 `Agent`、`Runner` 和 `run_internal` 的职责分工
- 能解释 tools、guardrails、sessions、tracing 为什么都属于运行时的一部分
- 能分清 `Session`、sandbox memory、snapshot 三者的边界
- 看一个 sandbox 示例时，能快速判断它主要在验证哪一层能力

## 易错点

- 从 `examples/` 直接开始，最后只记住用法，不记得执行链
- 把 `run_internal/` 当成纯实现细节，错过真正的 runtime 骨架
- 把 sandbox memory 和 snapshot 混成一种“记住过去”的机制
- 看项目卡时只看 prompt，不看 manifest、artifact 和 eval contract

## 我的理解

研究这套 SDK 时，最值得先固定的是“先 runtime，后 sandbox，再项目卡”的顺序。

只要把这个顺序固定下来，这组页面就不再是散页，而会变成一条从执行骨架到长任务工作流的连续学习线。

## 相关笔记

- [[../../10-领域/AI工程/OpenAI Agents SDK/OpenAI Agents SDK 总览]]
- [[OpenAI Agents SDK 学习总览]]
- [[OpenAI Agents SDK 示例与学习路径]]
