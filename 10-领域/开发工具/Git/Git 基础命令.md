---
tags:
  - 领域
  - Git
  - 命令
type: note
---

# Git 基础命令

## 这是什么

这篇笔记整理的是日常最常用的 Git 基础命令。

它的重点不是背命令大全，而是先建立一个最小模型：每条命令到底是在操作工作区、暂存区、本地仓库，还是远程仓库。

## 为什么重要

- 很多 Git 命令之所以容易混，不是命令本身难，而是没有先想清楚它在操作哪一层
- 先建立“工作区 -> 暂存区 -> 本地仓库 -> 远程仓库”这条主线，后面的命令会更容易归类
- 这篇适合当查表页，但前提是先有一个结构化理解

## 先记住一个最小模型

- 工作区：你正在改的文件
- 暂存区：准备提交的内容
- 本地仓库：已经提交过的历史
- 远程仓库：和别人协作或备份时用的仓库

很多 Git 命令之所以容易混，就是因为没有先想清楚“这条命令是在操作哪一层”。

## 最常见的日常主线

```bash
git status
git add .
git commit -m "说明这次做了什么"
git pull --rebase origin main
git push origin main
```

如果只记一条主线，先记住这一套。

## 仓库初始化

### `git init`

作用：把当前目录初始化成一个 Git 仓库。

```bash
git init
git init MyProject
```

适用场景：

- 一个本地文件夹刚开始接入版本管理

### `git clone <仓库地址>`

作用：从远程拉一份完整仓库到本地，包含历史记录。

```bash
git clone https://github.com/xxx/repo.git
git clone git@github.com:xxx/repo.git
```

适用场景：

- 第一次把远程项目拉到本地

## 查看与提交变更

### `git status`

作用：看当前有哪些文件改了，哪些还没跟踪，哪些已经暂存。

```bash
git status
git status -s
```

这是最值得高频使用的命令之一，因为它能先帮我看清现场。

### `git add <文件>`

作用：把修改放进暂存区。

```bash
git add README.md
git add .
git add docs
```

这里最重要的理解是：

- `git add` 不是“提交”
- 它只是告诉 Git：这些改动我准备提交

### `git commit -m "提交信息"`

作用：把暂存区内容提交到本地历史中。

```bash
git commit -m "新增 Git 笔记结构"
git commit -am "修改已跟踪文件"
```

注意：

- `-am` 只对已跟踪文件有效
- 新文件还是要先 `git add`

## 撤回与恢复

### `git reset HEAD <文件>`

作用：取消暂存，但保留工作区修改。

```bash
git reset HEAD README.md
```

适用场景：

- `git add` 加多了，想从暂存区拿出来

### `git checkout -- <文件>`

作用：丢弃工作区对某个文件的修改，恢复到最近一次提交状态。

```bash
git checkout -- notes.md
```

危险点：

- 这会直接丢掉当前改动
- 如果没有别的备份，通常无法恢复

## 分支操作

### `git branch`

作用：查看分支。

```bash
git branch
git branch -a
```

### `git branch <分支名>`

作用：基于当前分支新建一个分支。

```bash
git branch feature/login
```

### `git checkout <分支名>`

作用：切换分支。

```bash
git checkout feature/login
git checkout -b feature/register
```

我的理解：

- `git branch` 偏“创建/查看”
- `git checkout` 偏“切换”
- `git checkout -b` 是创建并切换，一步完成

### `git merge <分支名>`

作用：把指定分支合并到当前分支。

```bash
git checkout main
git merge feature/login
```

关键点：

- 合并前先确认自己站在目标分支上
- `git merge feature/login` 的含义是“把 feature/login 合并进当前分支”

## 远程仓库同步

### `git remote -v`

作用：查看远程仓库地址。

```bash
git remote -v
```

### `git remote add origin <地址>`

作用：给本地仓库绑定远程仓库。

```bash
git remote add origin https://github.com/TTW-F/Obsidian.git
```

### `git push <远程名> <分支名>`

作用：把本地提交推到远程。

```bash
git push origin main
git push --set-upstream origin main
```

### `git pull <远程名> <分支名>`

作用：把远程更新拉到本地并合并。

```bash
git pull origin main
git pull
```

### `git fetch`

作用：只获取远程更新，不自动合并。

```bash
git fetch origin
```

## 查看历史

### `git log`

作用：查看提交历史。

```bash
git log
git log --oneline
git log --graph --oneline --all
```

### `git show <提交ID>`

作用：看某次提交具体改了什么。

```bash
git show a1b2c3d
```

## 一个最容易混的地方

很多新手会把这几条命令混在一起：

- `git add`
- `git commit`
- `git push`

但其实它们分别在做三件不同的事：

- `add`：从工作区放进暂存区
- `commit`：从暂存区写进本地历史
- `push`：从本地历史发到远程

这组区分一旦清楚，Git 就会容易很多。

## 易错点

- 容易把 `git add` 当成提交
- 容易把 `git pull` 和 `git fetch` 混在一起
- 容易忽略 `git checkout -- 文件` 的破坏性
- 容易只背命令，不记它在操作哪一层

## 我的理解

Git 基础命令真正该记住的，不是数量，而是路径：

工作区、暂存区、本地仓库、远程仓库之间，改动到底在往哪里流。

只要这条路径清楚了，大部分基础命令都会变得顺理成章。

## 相关笔记

- [[Git 与 GitHub 总览]]
- [[Git 工作流]]
