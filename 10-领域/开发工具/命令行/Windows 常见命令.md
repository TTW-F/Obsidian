---
tags:
  - 领域
  - 命令行
  - Windows
  - 命令
type: note
---

# Windows 常见命令

## 这篇笔记要解决什么

这篇主要整理我在 Windows 命令行里最常碰到的高频命令，不求覆盖全部，只求能解决日常操作、排错和定位问题。

## 先记住三个使用原则

- 先看清当前目录，再执行会改文件的命令
- 带删除能力的命令要格外谨慎
- 看不懂命令时，先用 `help` 查参数

## 1. 目录操作

### `cd`

作用：切换当前目录。

```bat
cd D:\Git_Obsidian
cd ..
cd \
```

我的理解：

- `cd` 是所有命令的起点
- 很多命令“执行错地方”，本质上不是命令错，而是目录错

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

### `tree`

作用：按树形显示目录结构。

```bat
tree D:\Git_Obsidian
tree /f
```

适用场景：

- 观察一个目录的整体结构

## 2. 文件操作

### `type`

作用：查看文本文件内容。

```bat
type README.md
type D:\Notes\笔记.txt
```

适合：

- 快速看小文件

### `copy`

作用：复制文件。

```bat
copy README.md D:\Backup
copy *.txt D:\TextFiles
```

### `move`

作用：移动或重命名文件/文件夹。

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

危险点：

- 这类删除不是走回收站思路来理解的
- 执行前先确认范围，尤其是通配符

## 3. 系统与进程信息

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

我的理解：

- `tasklist` 先看
- `taskkill` 再动手

### `ver`

作用：快速查看 Windows 版本号。

```bat
ver
```

## 4. 网络排查

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

网络排查时我通常这样想：

- `ping` 看能不能通
- `nslookup` 看域名有没有正常解析
- `tracert` 看卡在哪一跳

## 5. 其他高频命令

### `cls`

作用：清屏。

```bat
cls
```

### `set`

作用：查看或设置环境变量。

```bat
set
set PATH
```

### `help`

作用：查看命令帮助。

```bat
help
help dir
help ping
```

### `exit`

作用：退出当前命令行窗口。

```bat
exit
```

## 新手最容易踩的坑

- 先确认自己在哪个目录，再执行删除或移动命令
- 许多命令参数前是 `/`，不是 `-`
- 通配符比如 `*.log` 很方便，但范围也很大
- 管道 `|` 是把前一个命令的输出传给后一个命令处理

## 我以后可以继续补什么

- PowerShell 常见命令
- 路径与相对路径
- 环境变量原理
- Windows 文件权限与进程排查

## 相关笔记

- [[命令行总览]]
- [[Ubuntu 常见命令]]
