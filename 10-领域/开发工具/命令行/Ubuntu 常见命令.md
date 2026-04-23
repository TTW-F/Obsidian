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

## 这篇笔记要解决什么

这篇整理我在 Ubuntu 终端里最常用的高频命令，重点不是“背命令大全”，而是先建立一套终端里的基本操作感。

## 先记住四个使用原则

- Linux 路径和命令通常区分大小写
- 删除命令要比查看命令更谨慎
- 先确认当前目录，再执行会修改文件的命令
- 看不懂时先查 `man`

## 1. 目录操作

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

我的理解：

- `cd ~` 回到当前用户主目录
- `cd /` 回到系统根目录
- 终端里很多操作是否安全，先看你站在哪个目录

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

### `tree`

作用：树形查看目录结构。

```bash
tree
tree /home/user/Git_Obsidian
tree -f
```

## 2. 文件操作

### `touch`

作用：创建空文件，或更新时间戳。

```bash
touch README.md
touch notes.txt test.log
touch existing.txt
```

### `echo`

作用：输出文本，或把内容写入文件。

```bash
echo "# 我的 Obsidian 笔记仓库" > README.md
echo "新增笔记分类" >> README.md
echo "当前目录：$(pwd)"
```

关键点：

- `>` 是覆盖写入
- `>>` 是追加写入

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
mv /home/user/Temp/test.log ./logs
```

### `rm`

作用：删除文件。

```bash
rm README.md
rm *.log
rm -f test.txt
```

危险点：

- Linux 下删除通常不按“回收站”来理解
- 通配符范围一定要确认

## 3. 系统与进程信息

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

### `free`

作用：查看内存使用情况。

```bash
free -h
```

### `df`

作用：查看磁盘使用情况。

```bash
df -h
```

## 4. 网络排查

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

## 5. 其他高频命令

### `clear`

作用：清屏。

```bash
clear
```

### `history`

作用：查看命令历史。

```bash
history
history | grep git
!100
```

### `env` / `echo $PATH`

作用：查看环境变量。

```bash
env
echo $PATH
```

### `man`

作用：查看命令手册。

```bash
man ls
man ping
```

### `exit`

作用：退出当前终端。

```bash
exit
```

## 新手最容易踩的坑

- Linux 区分大小写，路径拼错会直接找不到
- `sudo` 很强，但也意味着风险更高
- `rm -rf` 一定先确认目录
- `>` 和 `>>` 的区别要记住
- 长时间运行的命令可以用 `Ctrl + C` 中断

## 我以后可以继续补什么

- Linux 权限模型
- Shell 基础
- 常见日志查看命令
- SSH 与远程连接

## 相关笔记

- [[命令行总览]]
- [[Windows 常见命令]]
