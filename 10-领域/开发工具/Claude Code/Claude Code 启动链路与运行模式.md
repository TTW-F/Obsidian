---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - 启动流程
  - 运行模式
type: area
---

# Claude Code 启动链路与运行模式

## 这是什么

这篇笔记记录 Claude Code 从启动到进入具体运行模式的大致路径。

它真正想回答的是：一个复杂 agent 产品在“真正进入对话前”已经做了哪些准备、判断和分流。

## 为什么重要

- 启动阶段决定的不只是程序能不能起来，还决定哪些能力当前可用
- settings、policy、auth、MCP、feature flag 等很多治理逻辑都会在这里先收口
- Claude Code 的复杂度有一大块就藏在启动和模式分流阶段

## 核心入口在哪里

我现在最先看的入口是：

- `src/main.tsx`

从这个文件能看出，Claude Code 不是“启动后直接开聊”的简单 CLI，而是一个多模式共享 runtime 的产品。

## 这条启动链可以先怎样理解

### 1. 先做并行预热

在真正进入主逻辑前，`main.tsx` 会尽量把重活并行启动，例如：

- MDM settings 预读
- keychain 预取
- GrowthBook 初始化
- bootstrap / policy / managed settings 加载

这类设计很像把等待时间提前隐藏到启动阶段。

### 2. 再做环境和模式判定

启动后不是立即进入单一路径，而是要先判断：

- 当前是交互式还是非交互式
- 是否启用 remote / bridge
- 某些 feature flag 是否打开
- 当前 settings / policy / auth / MCP 状态是否满足入口条件

### 3. 最后进入具体运行模式

Claude Code 的真正入口不止一个，至少会分到：

- REPL
- 本地命令执行
- session resume
- remote session
- direct connect / bridge

## 为什么“运行模式”这件事本身很重要

如果 Claude Code 只保留一种交互路径，像 REPL、bridge、entrypoints 之间的状态切换和初始化依赖就不会这么复杂。

但 Claude Code 同时支持 REPL、非交互模式、bridge、remote 等入口后，就必须在启动时先回答：

- 这一轮是由谁驱动
- 哪些能力应该暴露
- 哪些外部依赖必须先准备好
- 哪些特性在当前环境里根本不该出现

## 一个具体场景怎么理解这层

比如同样是启动 Claude Code：

- 在本地交互式 REPL 下，系统要准备用户交互和会话能力
- 在 remote / bridge 模式下，系统还要处理连接、控制权和远程状态

这两个场景共用核心 runtime，但绝不会走完全相同的入口流程。

## 这里最值得记住的点

- `main.tsx` 更像产品启动编排器，而不是薄薄一层参数解析
- 启动链路已经承担了性能优化、权限收口、模式切换和外部依赖预热
- 多模式共享 runtime 是 Claude Code 复杂度的重要来源

## 易错点

- 容易把 `main.tsx` 理解成单纯参数解析入口
- 容易假设 Claude Code 只有一种运行方式
- 容易忽略启动阶段的预热和模式判定，实际它们会直接影响后续可用能力

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 源码结构]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
