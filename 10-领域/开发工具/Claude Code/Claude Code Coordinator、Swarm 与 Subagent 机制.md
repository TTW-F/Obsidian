---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Coordinator
  - Swarm
  - Subagent
type: area
---

# Claude Code Coordinator、Swarm 与 Subagent 机制

## 这是什么

这篇笔记记录 Claude Code 里已经落地的多代理运行机制：子代理怎么定义、怎么分工、怎么隔离、怎么协作。

可以先把它看成 Claude Code 里一套“角色对象化”的多代理实现，而不只是“多开几个 agent”。

## 为什么重要

- 如果 Claude Code 只支持一个前台 agent，那么命令、工具、权限、任务很多设计都可以简单得多
- 但只要开始支持 subagent、teammate、background agent、coordinator / worker，系统就必须回答角色边界、权限缩放、上下文缩放和执行隔离这些问题
- 多代理能力是否成体系，会直接影响平台后续能不能继续扩成更复杂的工作流

## 关键入口

- `src/tools/AgentTool/AgentTool.tsx`
- `src/tools/AgentTool/runAgent.ts`
- `src/tools/AgentTool/loadAgentsDir.ts`
- `src/utils/swarm/`
- `src/coordinator/coordinatorMode.ts`

这些位置说明，在 Claude Code 里，“代理”已经是正式运行单元，而不是主代理临时拼出来的技巧。

## Claude Code 里的多代理不是同一种东西

从目录和配置能力看，它至少区分了：

- subagent
- teammate
- background agent
- coordinator / worker
- worktree / remote isolation

这说明多代理不只是并发数量变化，而是角色类型和执行语义都在变化。

## AgentTool 为什么是关键入口

`AgentTool` 是主代理调用子代理的入口。

它不只是传一段 prompt，而是还要决定：

- agent type
- 工具边界
- permission mode
- model / effort
- skills / MCP servers
- background 与否
- isolation 模式

这说明子代理不是主代理的简单复制品，而是带角色配置的执行单元。

## agent definition 为什么重要

`loadAgentsDir.ts` 很值得记住，因为它把 agent 变成了“可配置资源”。

一个 agent definition 可以声明：

- prompt
- tools / disallowedTools
- skills
- hooks
- permissionMode
- maxTurns
- model / effort
- memory
- isolation

这意味着 Claude Code 对“代理”的理解已经是可加载、可裁剪、可隔离的角色对象。

## coordinator 和 swarm 在补什么

`utils/swarm/` 和 `coordinator/coordinatorMode.ts` 说明 Claude Code 已经不满足于单纯 subagent 调用，而是在探索：

- 主从协作
- 团队布局
- 权限同步
- 协调者与执行者的角色分离

这里最值得记住的，是 `loadAgentsDir.ts`、`AgentTool.tsx`、`utils/swarm/`、`coordinatorMode.ts` 分别在承接角色定义、角色实例化、团队协作和协调模式。

## 一个具体场景怎么理解这层

比如主代理收到一个大任务后，可能会：

1. 由 coordinator 保留总体目标和结果整合
2. 派 worker 去查代码和文件结构
3. 派另一个 worker 做实现或验证
4. 让 background agent 持续跑长任务
5. 最后把结果重新汇总回主线

这个场景能帮助我记住：多代理系统真正难的，不是派出去，而是怎么定义角色、收回结果和控制边界。

## 最值得记住的点

- `loadAgentsDir.ts` 让角色定义可以脱离主循环单独加载
- `AgentTool.tsx` 决定一次子代理调用时到底带哪些工具、权限和隔离参数
- `utils/swarm/` 与 `coordinatorMode.ts` 说明团队协作不是单点调用，而是单独一层编排
- worktree、remote isolation、background 执行都和多代理角色设计绑在一起

## 易错点

- 容易把子代理理解成主代理的简单复制品
- 容易把多代理问题只看成并发问题，而忽略角色分工、权限同步和结果回收
- 容易忽视隔离，worktree、remote isolation、background 执行这些都和多代理设计绑在一起
- 容易只看 `AgentTool` 调用点，而忽略 `loadAgentsDir.ts`、`utils/swarm/`、`coordinatorMode.ts` 这些位置共同构成了角色定义、团队编排和执行隔离三层结构

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code Worktree、Remote Isolation 与执行隔离]]
- [[../../../20-主题/Agentic CLI/多代理协作]]
