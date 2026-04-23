---
tags:
  - 领域
  - 命令行
  - Ubuntu
  - Linux
  - 命令
type: note
---

# Ubuntu 常见命令

## 这是什么

这篇整理的是我在 Ubuntu 终端里最常用的高频命令。

重点不是“背命令大全”，而是先建立一套终端里的基本操作感：路径怎么走、文件怎么查、进程怎么管、网络怎么排。

## 为什么重要

- Linux 命令行里最常见的问题，不是命令不会写，而是路径、权限和范围没先想清楚
- 高频命令整理好之后，很多日常操作和排错都会更顺手
- 这篇更适合做高频查表页，而不是系统化 Linux 教程

## 先记住四个使用原则

- Linux 路径和命令通常区分大小写
- 删除命令要比查看命令更谨慎
- 先确认当前目录，再执行会修改文件的命令
- 看不懂时先查 `man`

## 目录操作

### `pwd`

作用：查看当前所在目录。

```bash
pwd
```

这是我在不确定位置时最先用的命令之一。

### `cd`

作用：切换目录。

```bash
cd /home/user/Git_Obsidian
cd ..
cd ~
cd /
```

这里最重要的不是命令本身，而是终端里很多操作是否安全，先看你站在哪个目录。

### `ls`

作用：查看目录内容。

```bash
ls
ls -l
ls -a
ls -lh
ls /home
```

常用理解：

- `-l` 看详细信息
- `-a` 看隐藏文件
- `-h` 让文件大小更容易读

### `mkdir`

作用：创建目录。

```bash
mkdir Obsidian_Notes
mkdir -p /home/user/Temp/Test
mkdir docs logs
```

### `rmdir` / `rm -r`

作用：删除目录。

```bash
rmdir Temp
rm -r Temp
rm -rf Temp
```

危险点：

- `rmdir` 只能删空目录
- `rm -r` 会递归删除
- `rm -rf` 风险最高，确认路径后再执行

## 文件操作

### `touch`

作用：创建空文件，或更新时间戳。

```bash
touch README.md
touch notes.txt test.log
```

### `cat` / `less`

作用：查看文本内容。

```bash
cat README.md
less README.md
```

我的使用习惯：

- 小文件用 `cat`
- 稍长的文件优先用 `less`

### `cp`

作用：复制文件或目录。

```bash
cp README.md /home/user/Backup
cp -r Obsidian_Notes /home/user/Backup
cp *.txt /home/user/TextFiles
```

### `mv`

作用：移动文件，或者重命名。

```bash
mv Notes.txt /home/user/Obsidian
mv OldFolder NewFolder
```

### `rm`

作用：删除文件。

```bash
rm README.md
rm *.log
rm -f test.txt
```

Linux 下删除通常不按“回收站”来理解，所以范围确认尤其重要。

## 系统与进程信息

### `uname`

作用：查看系统内核信息。

```bash
uname -a
uname -r
```

### `lsb_release -a`

作用：查看 Ubuntu 版本信息。

```bash
lsb_release -a
```

### `ps`

作用：查看进程。

```bash
ps -aux
ps -ef | grep git
ps -aux | grep obsidian
```

### `kill` / `killall`

作用：结束进程。

```bash
kill 1234
kill -9 1234
killall obsidian
```

我的理解：

- 先 `ps` 找进程
- 再 `kill`
- `-9` 是更强硬的结束方式，不是第一选择

## 网络排查

### `ip addr`

作用：查看网络接口和 IP 信息。

```bash
ip addr
```

### `ping`

作用：测试网络连通性。

```bash
ping github.com
ping -c 5 github.com
ping 223.5.5.5
```

### `traceroute`

作用：追踪网络路径。

```bash
traceroute github.com
```

### `nslookup` / `dig`

作用：检查 DNS 解析。

```bash
nslookup github.com
dig github.com
```

### `curl` / `wget`

作用：测试 HTTP 请求或下载文件。

```bash
curl https://github.com
wget https://example.com/file.txt
```

网络排查时我通常这样想：

- `ping` 看是否能通
- `nslookup` / `dig` 看解析是否正常
- `traceroute` 看卡在哪一段
- `curl` 看 HTTP 服务是否可达

## 一个最常见的错误场景

很多 Ubuntu 命令的风险不是来自命令名，而是：

- 没确认当前目录
- 没意识到大小写敏感
- 在不清楚作用范围时直接用了 `rm -rf`

所以“先看路径和范围”比“背更多命令”更重要。

## 易错点

- 容易忽略 Linux 区分大小写
- 容易把 `sudo` 当成默认前缀，而忽略风险
- 容易低估 `rm -rf` 的破坏性
- 容易忘了 `>` 和 `>>` 的区别

## 我的理解

Ubuntu 常见命令最值得记住的，不是每条命令的所有参数，而是：

- 先确认自己在哪
- 再确认命令会影响什么

只要路径感和范围感建立起来，终端就会稳定很多。

## 相关笔记

- [[命令行总览]]
- [[Windows 常见命令]]
