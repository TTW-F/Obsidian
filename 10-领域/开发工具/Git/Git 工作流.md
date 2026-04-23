---
tags:
  - 领域
  - Git
  - 工作流
type: note
---

# Git 工作流

## 这篇笔记要解决什么

这篇不讲零散命令，而是讲我在日常开发里应该按什么顺序使用 Git，才能少踩坑、少冲突、少慌张。

## 最小工作流

一个最常见的日常循环可以理解成：

1. 先同步最新代码
2. 在当前分支上修改文件
3. 查看变更
4. 暂存
5. 提交
6. 推送

对应命令通常是：

```bash
git pull --rebase origin main
git status
git add .
git commit -m "说明这次修改"
git push origin main
```

## 如果是做新功能

我更推荐这样走：

1. 先更新主分支
2. 从主分支切新分支
3. 在功能分支开发
4. 提交并推送功能分支
5. 再去合并

```bash
git checkout main
git pull --rebase origin main
git checkout -b feature/xxx
git status
git add .
git commit -m "实现 xxx"
git push --set-upstream origin feature/xxx
```

## 我对这个流程的理解

- `pull` 是先把远程最新内容同步下来
- `status` 是看清现场
- `add` 是确定哪些内容准备提交
- `commit` 是把这次修改写进本地历史
- `push` 是把本地结果发到远程

这套顺序的核心价值是：

每一步都在降低不确定性。

## 提交前我会检查什么

- 当前是不是站在对的分支上
- 有没有不该提交的文件
- 提交信息是不是能说明“这次改了什么”

## 容易出问题的几个场景

### 1. 没同步就直接写

结果：

- 推送时容易冲突
- 甚至会误覆盖别人改动

### 2. 什么都 `git add .`

结果：

- 可能把临时文件、测试文件、无关修改一起提交

我的改进方式：

- 重要提交前先看一次 `git status`

### 3. 提交信息太空

比如：

- `update`
- `修改`
- `test`

这种信息过几天基本等于没写。

更好的写法：

- `补充 Git 工作流笔记`
- `重构数组主题结构`
- `新增二分查找模板`

## 我的默认习惯

- 修改前先 `git pull --rebase`
- 提交前先 `git status`
- 尽量一件事一个提交
- 先写清楚提交信息，再推送

## 以后可以继续补什么

- rebase 的使用场景
- merge 和 rebase 的区别
- 冲突处理
- stash 的使用时机

## 相关笔记

- [[Git 基础命令]]
- [[Git 与 GitHub 总览]]
