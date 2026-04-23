---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - Shell
  - 文件系统
  - 安全
type: area
---

# Claude Code 文件系统与 Shell 安全模型

## 这是什么

这篇记的是 `Claude Code` 怎样给文件操作和 Shell 执行加护栏。

对 coding agent 来说，这不是附属问题，而是执行能力能不能放心放开的前提。

## 为什么这块重要

Claude Code 这类 coding agent 一旦能：

- 读文件
- 写文件
- 执行 Shell / PowerShell
- 调外部工具

就天然处在高风险区域。

所以它真正要解决的，不是“能不能执行”，而是“在什么边界里执行”。

## 关键模块

从目录与文件命名看，Claude Code 对这块投入很重：

- `src/utils/permissions/`
- `src/utils/shell/`
- `src/utils/powershell/`
- `src/utils/sandbox/`
- `src/tools/BashTool/`
- `src/tools/PowerShellTool/`
- `src/utils/permissions/filesystem.ts`

我先把这件事记成一句话：
文件系统和 Shell 安全不是某个工具自己的问题，而是平台级治理问题。

## 我现在先这样理解它的几层边界

### 1. 工具级边界

不同工具的危险等级不同：

- 文件读取
- 文件编辑 / 写入
- Bash / PowerShell
- 子代理

Claude Code 没有把它们当成一个抽象“执行工具”，而是分别建模。

### 2. 规则级边界

从权限系统可以看出，放行并不是只有 allow / deny 两种粗粒度控制。

它还会继续细分到：

- 工具名
- 命令前缀
- 目录
- 模式切换
- 是否是危险规则

这让安全边界可以既严格又不至于完全不可用。

### 3. Shell 语义级边界

`utils/shell/` 和 `utils/powershell/` 的存在说明，Claude Code 不满足于“字符串匹配一下命令”。

它在尝试理解：

- 默认 shell
- prefix 规则
- 只读命令验证
- PowerShell 特有危险 cmdlet

也就是说，它已经在把 shell 当成一种“带语义的执行环境”来治理。

### 4. 沙箱与隔离边界

从 `utils/sandbox/`、worktree、remote isolation 等线索看，Claude Code 不只靠权限规则，也在考虑执行环境隔离。

这类隔离可以缓解：

- 文件误改
- 工作区污染
- 跨代理互相覆盖

## 这里最值得记住的点

- 文件操作和 Shell 操作必须纳入统一权限体系
- PowerShell 不应该简单复用 Bash 的安全模型
- 危险规则识别要比权限弹窗更早发生
- 安全边界最好同时包含规则、语义理解和环境隔离三层

## 易错点

- 不要把 Shell 安全只理解成“命令黑名单”。
  Claude Code 明显还在做前缀规则、只读校验和 PowerShell 特定危险模式识别。
- 不要把权限规则当成唯一护栏。
  worktree、sandbox、remote isolation 这些环境级隔离同样重要。
- 不要假设 Bash 和 PowerShell 可以共用同一套风险判断。
  Windows 环境下 PowerShell 的危险入口明显不一样。

## 我的理解

Claude Code 真正体现工程成熟度的一个点，是它没有把“执行能力”当作炫技，而是一直在给执行能力加护栏。

## 相关笔记

- [[Claude Code 总览]]
- [[Claude Code 阅读路径与关键文件入口]]
- [[Claude Code 输入预处理、工具调度与权限插入]]
- [[Claude Code 模型 API 适配层]]
- [[../../../20-主题/Agentic CLI/权限与安全边界]]
