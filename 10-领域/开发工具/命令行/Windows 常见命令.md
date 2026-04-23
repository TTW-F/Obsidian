---
tags:
  - 领域
  - 命令行
  - Windows
  - 命令
type: note
---

# Windows 常见命令

## 这是什么

这篇整理的是我在 Windows 命令行里最常碰到的高频命令。

重点不是“背完所有命令”，而是先建立一套日常操作感：目录怎么看、文件怎么改、进程怎么查、网络怎么排。

## 为什么重要

- Windows 命令行里最容易出问题的不是命令本身，而是目录、范围和参数没看清
- 高频命令整理好之后，很多日常排错和文件操作都会更顺手
- 这篇更适合当高频查表页，而不是系统教程

## 先记住三个使用原则

- 先看清当前目录，再执行会改文件的命令
- 带删除能力的命令要格外谨慎
- 看不懂命令时，先用 `help` 查参数

## 目录操作

### `cd`

作用：切换当前目录。

```bat
cd D:\Git_Obsidian
cd ..
cd \
```

这里最重要的不是命令本身，而是很多命令“执行错地方”，本质上不是命令错，而是目录错。

### `dir`

作用：查看当前目录内容。

```bat
dir
dir /a
dir /w
```

常用场景：

- 看文件是否存在
- 看隐藏文件
- 快速确认当前目录结构

### `md` / `mkdir`

作用：创建目录。

```bat
md Obsidian_Notes
mkdir D:\Temp
```

### `rd` / `rmdir`

作用：删除目录。

```bat
rd Temp
rd /s Temp
```

危险点：

- `rd /s` 会递归删除目录内容
- 删除前一定确认路径

## 文件操作

### `type`

作用：查看文本文件内容。

```bat
type README.md
type D:\Notes\笔记.txt
```

适合快速看小文件。

### `copy`

作用：复制文件。

```bat
copy README.md D:\Backup
copy *.txt D:\TextFiles
```

### `move`

作用：移动或重命名文件 / 文件夹。

```bat
move Notes.txt D:\Obsidian
move OldFolder NewFolder
```

### `ren`

作用：重命名。

```bat
ren 旧文件名.txt 新文件名.txt
ren OldDir NewDir
```

### `del`

作用：删除文件。

```bat
del README.md
del *.log
del /f readonly.txt
```

这类命令最容易出问题的地方是范围，尤其是通配符。

## 系统与进程信息

### `systeminfo`

作用：看系统详细信息。

```bat
systeminfo
systeminfo | find "操作系统名称"
```

### `tasklist`

作用：看当前进程。

```bat
tasklist
tasklist | find "obsidian"
```

### `taskkill`

作用：结束进程。

```bat
taskkill /f /im obsidian.exe
taskkill /pid 1234
```

我的习惯是：

- 先 `tasklist` 看清楚
- 再 `taskkill`

## 网络排查

### `ipconfig`

作用：查看本机网络配置。

```bat
ipconfig
ipconfig /all
```

### `ping`

作用：测试目标地址是否能连通。

```bat
ping github.com
ping 223.5.5.5
ping -n 5 github.com
```

### `tracert`

作用：看网络请求经过哪些节点。

```bat
tracert github.com
```

### `nslookup`

作用：查域名解析结果。

```bat
nslookup github.com
```

我通常这样想：

- `ping` 看能不能通
- `nslookup` 看域名有没有正常解析
- `tracert` 看卡在哪一跳

## 一个最常见的错误场景

很多 Windows 命令的风险并不在语法，而在于：

- 当前目录站错了
- 通配符范围看错了
- `/s`、`/f` 这类参数没意识到后果

所以“先确认目录和范围”比“背更多命令”更重要。

## 易错点

- 容易先执行再确认目录
- 容易忽略 Windows 下很多参数前缀是 `/` 不是 `-`
- 容易低估通配符和递归删除参数的破坏性

## 我的理解

Windows 常见命令最值得记住的，不是每个命令长什么样，而是两个动作：

- 先确认自己在哪
- 再确认命令会影响哪里

这两步做稳了，大多数日常命令就不容易出大问题。

## 相关笔记

- [[命令行总览]]
- [[Ubuntu 常见命令]]
