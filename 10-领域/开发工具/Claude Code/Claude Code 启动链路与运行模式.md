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

## 研究边界

这篇只记录 `Claude Code` 自身的启动与入口分流，不展开成通用 agent 启动框架总论。

## 入口文件

核心入口是 `src/main.tsx`。

从这个文件可以看到，Claude Code 不是“启动后直接开聊”的简单 CLI，而是一个多模式共享 runtime 的产品：

- CLI 参数模式
- 交互式 REPL
- SDK / headless
- bridge / remote control
- assistant / coordinator 等 feature-gated 入口

## 我看到的启动设计

### 1. 先做并行预热

在真正进入主逻辑之前，`main.tsx` 会尽量把重活并行启动：

- MDM settings 预读
- keychain 预取
- GrowthBook 初始化
- bootstrap / policy / managed settings 加载

这个设计很像“把用户等待时间隐藏到 import 期间”。

### 2. 再做环境和模式判定

启动后不是马上进入单一路径，而是先判断：

- 当前是交互式还是非交互式
- 当前是否启用 remote / bridge
- 当前是否允许某些 feature flag
- 当前 settings / policy / auth / MCP 状态是否满足入口条件

### 3. 最后才进入具体运行模式

Claude Code 的真正入口不是一个，而是多条：

- REPL
- 本地命令执行
- session resume
- remote session
- direct connect / bridge

## 这说明了什么

- `main.tsx` 更像“产品启动编排器”，不是薄薄一层参数解析
- 一个成熟 agent CLI 的复杂度，很多都堆在启动阶段
- 启动链路已经承担了性能优化、权限收口、模式切换、外部依赖预热这些职责

## 我提炼出的阅读顺序

如果以后继续深挖启动流程，我会按这个顺序读：

1. `src/main.tsx`
2. `src/entrypoints/`
3. `src/replLauncher.tsx`
4. `src/interactiveHelpers.tsx`
5. `src/bootstrap/state.ts`
6. `src/remote/`
7. `src/bridge/`

## 我的理解

Claude Code 的启动阶段已经暴露出一个事实：
它不是“模型能力 + 几个工具”的演示品，而是一个需要精细启动治理的运行平台。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 源码结构]]
- [[Claude Code Agent 主循环与工具执行]]
- [[Claude Code 扩展总线：Skills、Plugins、MCP]]
