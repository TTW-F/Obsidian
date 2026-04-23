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

## 研究边界

这篇聚焦 `Claude Code` 已落地的多代理运行机制，不展开成抽象多 agent 协作理论。

## 关键文件

- `src/tools/AgentTool/AgentTool.tsx`
- `src/tools/AgentTool/runAgent.ts`
- `src/tools/AgentTool/loadAgentsDir.ts`
- `src/utils/swarm/`
- `src/coordinator/coordinatorMode.ts`

## 我看到的事实

Claude Code 里的多代理，不只是“起一个子任务”。

从目录和配置能力看，它已经至少区分了：

- subagent
- teammate
- background agent
- coordinator / worker
- worktree / remote isolation

这说明“代理”在系统里已经是一级运行单元。

## AgentTool 在做什么

`AgentTool` 是主代理调用子代理的入口。

从设计上看，它不只是传一段 prompt，而是还要决定：

- agent type
- 工具边界
- permission mode
- model / effort
- skills / MCP servers
- background 与否
- isolation 模式

这说明子代理不是主代理的简单复制品，而是带角色配置的执行单元。

## loadAgentsDir 给我的启发

`loadAgentsDir.ts` 很重要，因为它把 agent 变成了“可配置资源”。

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

这意味着 Claude Code 对“代理”的理解已经很接近插件化角色系统。

## swarm / coordinator 的意义

`utils/swarm/` 和 `coordinator/coordinatorMode.ts` 说明 Claude Code 已经不满足于单纯 subagent 调用，而是在探索：

- 主从协作
- 团队布局
- 权限同步
- 协调者与执行者的角色分离

这里最值得学的不是“并发”本身，而是“组织结构被编码进运行时”。

## 我提炼出的实现启发

- 多代理系统里，角色定义最好也是配置对象
- 子代理不应默认继承所有能力
- 协调者和执行者最好在 prompt、权限、工具上明确分工
- 隔离策略是多代理系统的关键组成，不是附属选项

## 我的理解

Claude Code 在多代理上的成熟度，不只是因为它能开子代理，而是因为它在认真处理角色、边界、隔离和协作协议。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[../../../20-主题/Agentic CLI/多代理协作]]
