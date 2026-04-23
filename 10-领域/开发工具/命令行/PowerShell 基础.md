---
tags:
  - 领域
  - 命令行
  - PowerShell
type: note
---

# PowerShell 基础

## 这是什么

PowerShell 可以先理解成 Windows 世界里更“面向对象”的命令行环境。

它当然能执行命令，但它最值得记住的地方不是“又一种 shell”，而是它传递的往往不是纯文本，而是对象。

这会直接影响我写命令的方式：

- 查看结果时，不只盯着字符串
- 过滤时，更多是按属性筛选
- 串联命令时，更多是在传对象而不是拼文本

## 为什么重要

- 如果只把 PowerShell 当成 CMD 的替代品，很容易错过它真正强的地方
- Windows 下很多系统管理、进程查看、服务操作都和 PowerShell 更贴合
- 现在很多 agent、自动化脚本和本地工具在 Windows 上也会直接调用 PowerShell

## 先记住一个核心差异

在 Bash 里，管道里经常流动的是文本。

在 PowerShell 里，管道里经常流动的是对象。

这意味着下面两种动作会变得很自然：

- 先拿到一批对象
- 再按属性过滤、排序、选择

例如：

```powershell
Get-Process
Get-Process | Where-Object { $_.ProcessName -like '*code*' }
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

这里最重要的不是背命令，而是形成这个意识：

我拿到的是“进程对象”，不是一堆等着手搓解析的文本。

## 最常见的三类命令

### 1. `Get-Command`

作用：查看当前可用命令。

```powershell
Get-Command
Get-Command *process*
Get-Command -CommandType Cmdlet
```

当我只记得一个动作，不记得精确命令名时，会先从这里找入口。

### 2. `Get-Help`

作用：查看命令帮助。

```powershell
Get-Help Get-Process
Get-Help Get-Process -Examples
Get-Help Get-ChildItem -Detailed
```

PowerShell 的帮助系统通常比“去搜一段命令”更稳，因为它能直接告诉我参数、例子和适用方式。

### 3. `Get-Member`

作用：查看对象有哪些属性和方法。

```powershell
Get-Process | Get-Member
Get-Service | Get-Member
```

这是很多初学者容易忽略，但特别关键的命令。

当我不知道一个对象能拿哪些字段时，先用 `Get-Member`，比猜属性名靠谱得多。

## 文件与目录操作

### `Get-ChildItem`

作用：查看目录内容。

```powershell
Get-ChildItem
Get-ChildItem -Force
Get-ChildItem -Recurse -Filter *.md
```

它有点像 `dir` 或 `ls`，但返回的是文件对象。

### `Set-Location`

作用：切换目录。

```powershell
Set-Location D:\Git_Obsidian
Set-Location ..
```

日常里我更多直接用 `cd`，因为它是别名，但知道原命令名更利于读脚本。

### `Copy-Item` / `Move-Item` / `Remove-Item`

作用：复制、移动、删除。

```powershell
Copy-Item .\note.md D:\Backup\
Move-Item .\draft.md .\done\
Remove-Item .\temp.txt
Remove-Item .\cache -Recurse
```

这里最该警惕的是 `Remove-Item -Recurse`，因为一旦路径看错，破坏范围会很大。

## 过滤、选择和格式化

### `Where-Object`

作用：过滤对象。

```powershell
Get-Process | Where-Object { $_.CPU -gt 100 }
Get-Service | Where-Object { $_.Status -eq 'Running' }
```

### `Select-Object`

作用：只取需要的字段，或者截取前几项。

```powershell
Get-Process | Select-Object ProcessName, CPU, Id
Get-ChildItem | Select-Object -First 10
```

### `Format-Table`

作用：把输出整理成更易读的表格。

```powershell
Get-Service | Select-Object Name, Status | Format-Table
```

要注意，`Format-*` 更偏向“展示”，通常应放在命令链最后。

## 一个很常见的场景

如果我想找出占 CPU 比较高的几个进程，可以这样想：

1. 先拿到进程对象
2. 再按 CPU 排序
3. 最后选前几项

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

这个例子很能体现 PowerShell 的工作习惯：先拿对象，再按属性处理。

## 别名很方便，但不要只记别名

PowerShell 里有很多顺手的别名，比如：

- `ls` 对应 `Get-ChildItem`
- `cd` 对应 `Set-Location`
- `cat` 对应 `Get-Content`

日常交互里用别名没问题，但看脚本、写可读性更高的命令时，我更倾向于记住正式命令名。

## 易错点

- 容易把 PowerShell 完全当成 Bash 来用，忽略对象模型
- 容易只记别名，不知道背后的正式命令
- 容易在删除或递归操作前不确认路径和范围
- 容易在还要继续处理数据时过早使用 `Format-Table`

## 我的理解

PowerShell 最值得先建立的不是“命令清单”，而是这句理解：

它擅长把系统对象拿出来，再按属性筛选和组合。

只要这层意识建立起来，后面很多命令就不再像零散招式，而更像一条统一的工作流。

## 相关笔记

- [[命令行总览]]
- [[Windows 常见命令]]
- [[Ubuntu 常见命令]]
- [[../Claude Code/Claude Code 文件系统与 Shell 安全模型]]
