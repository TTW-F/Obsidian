---
tags:
  - 源码镜像
  - Claude Code
  - OpenAI Agents SDK
  - AI_Writer
type: map
---

# AI_Writer vendor 源码镜像总览

## 这张地图覆盖什么

这页只负责给 `AI_Writer` 里迁入 Obsidian 的外部源码镜像提供统一入口，不重复展开具体实现细节。

我现在把这批内容单独放在 `40-源码镜像`，目的是把“正式知识笔记”和“原始源码实物”分开维护。

## 当前镜像位置

- `40-源码镜像/AI_Writer Vendor/claude-code`
- `40-源码镜像/AI_Writer Vendor/openai-agents-python`

## 建议从哪里开始看

如果是为了理解 Agentic CLI 产品骨架，先走 Claude Code 这条线：

- [[../../10-领域/开发工具/Claude Code/Claude Code 总览]]
- [[../../10-领域/开发工具/Claude Code/Claude Code 阅读路径与关键文件入口]]
- `40-源码镜像/AI_Writer Vendor/claude-code/src`

如果是为了理解 agent runtime、sandbox 与运行时编排，先走 OpenAI Agents SDK 这条线：

- [[../../10-领域/AI工程/OpenAI Agents SDK/OpenAI Agents SDK 总览]]
- [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK 执行主线与源码入口]]
- `40-源码镜像/AI_Writer Vendor/openai-agents-python/src/agents`

## 两条主线怎么分

### Claude Code

更适合研究：

- CLI 入口、REPL 与交互层
- 工具调度、权限、安全边界
- Skills、Plugins、MCP 与多代理机制

配套笔记入口：

- [[../../10-领域/开发工具/Claude Code/Claude Code 源码结构]]
- [[../../10-领域/开发工具/Claude Code/Claude Code Agent 主循环与工具执行]]
- [[../../10-领域/开发工具/Claude Code/Claude Code 扩展总线：Skills、Plugins、MCP]]
- [[Claude Code 目录到笔记映射]]

### OpenAI Agents SDK

更适合研究：

- `Agent -> Runner -> run_internal` 执行骨架
- tools、handoffs、guardrails、sessions、tracing
- sandbox memory、snapshot、artifact 契约

配套笔记入口：

- [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK run_internal 执行链路]]
- [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Memory]]
- [[../../20-主题/OpenAI Agents SDK/OpenAI Agents SDK Sandbox Snapshot 与恢复]]
- [[OpenAI Agents SDK 目录到笔记映射]]

## 维护约定

- `40-源码镜像` 只放外部源码镜像与少量索引说明，不在这里写长篇分析正文
- 正式沉淀继续放在 `10-领域` 和 `20-主题`
- 如果后面再迁入新的外部仓库，也优先挂到这一区域，而不是散落到现有主题目录

## 还缺什么

- Claude Code 的 `screens / components / bootstrap` 还可以继续往交互细节和初始化顺序拆
- OpenAI Agents SDK 的 `realtime / voice / mcp` 还可以继续补细拆页
