---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - 代码审查
  - 项目
type: note
source: D:\Git_Obsidian\Obsidian\40-源码镜像\AI_Writer Vendor\openai-agents-python\examples\sandbox\tutorials\repo_code_review
---

# 项目卡：sandbox repo_code_review 工作流

## 这是什么

`sandbox repo_code_review` 是一个用 OpenAI Agents SDK 搭建的代码审查工作流样例。

它展示的不是单条 code review prompt，而是一条完整闭环：

1. 挂载一个真实 git 仓库
2. 在隔离环境里运行测试、读取代码、检查变更
3. 以结构化结果返回 review findings
4. 把 review 产物写入输出目录
5. 用 eval 脚本校验结果是否满足契约

因此，这个项目更适合被理解为一个最小可运行的“代码审查 agent 项目卡”。

## 为什么重要

- 它展示的不是单个 API，而是一条从输入、运行、输出到评估都闭合的 sandbox 工作流
- 代码审查天然需要仓库、shell、patch 和结构化结果，这个项目把这些能力放在同一条链上
- 它很适合用来理解 agent 工作流怎样从 demo 走向可回归、可评估的系统

## 这个项目主要在验证什么

我现在会把它理解成在验证四件事：

1. sandbox 能否稳定挂载并审查一个真实仓库
2. agent 是否真的通过工具接触代码和测试结果，而不是只靠语言模型猜测
3. 审查结果能否被建模成结构化输出和独立 artifact
4. 整条工作流能否通过 eval 契约做回归校验

它的 contract 也故意收得很窄：

- 必须返回恰好两个 findings
- 一个针对 `repo/.github/workflows/test.yml`
- 一个针对 `repo/src/sample/simple.py`
- patch 只允许修改 `simple.py`

这种窄 contract 的价值在于，结果可以被精确检查，而不是停留在“看起来像是做对了”。

## 这个项目的工作流结构

### 输入层

这个项目的输入层很干净，只依赖两类核心输入：

- `AGENTS.md`
- 通过 `GitRepo(...)` 挂载的固定仓库与指定提交

这意味着：

- agent 有明确的工作规则来源
- 仓库输入可复现、可固定
- 每次运行面对的代码上下文是稳定的

### 运行层

运行层的关键不只是调用 agent，而是要求 agent 在 sandbox 中真正接触工作区。

这个项目里几个有代表性的设计是：

- 通过 `SandboxAgent` 进入隔离环境
- 通过 shell 和文件系统工具读代码、跑测试、生成 patch
- 使用 `Runner.run_streamed(...)` 承载这类长任务流程
- 通过 `tool_choice="required"` 强制 agent 用工具接触仓库

这里真正重要的是 grounded in workspace。对于代码审查这类任务，不读文件、不跑测试的结果通常不可靠。

### 输出层

输出层不是一段自然语言评论，而是被建模成程序可消费的数据结构。

`main.py` 中定义的 `ReviewFinding` 与 `RepoReviewResult` 会把结果整理为：

- `test_command`
- `test_result`
- `findings`
- `review_markdown`
- `fix_patch`

此外，结果还会被拆成独立 artifact 写盘：

- `review.md`
- `findings.jsonl`
- `fix.patch`

这说明真实工作流里的最终产物通常包括三类东西：给人读的总结、给机器消费的 findings、可直接应用的 patch。

### 评估层

评估层用 `evals.py` 检查结果是否满足 contract，例如：

- findings 数量必须是 2
- file path 必须精确命中目标文件
- workflow comment 必须提到 `nox` 和具体测试工具问题
- `simple.py` comment 必须提到 `add_one` 和 `-> int`
- patch 只能改 `simple.py`

这说明它验证的不是“agent 看起来像会做审查”，而是“代码审查工作流能不能变成一个有 contract、有 artifact、有校验的可回归系统”。

## 一个具体场景怎么理解这张项目卡

如果我想做一个可回归的审查型 agent，这个项目最值得抄的不是某条 prompt，而是它的骨架：

- 输入仓库固定
- agent 必须通过工具接触真实工作区
- 输出被拆成结构化结果和独立 artifact
- 最后再用 eval 契约检查结果是否合格

这个场景能帮助我记住：项目卡的价值，在于保留“工作流结构”，不是保留一段漂亮提示词。

## 最该记住的点

- 这不是 prompt 示例，而是一个完整的代码审查 agent 工作流切片
- `AGENTS.md` 在这里承担的是硬约束和工作规程，不只是补充说明
- 对审查类任务来说，`tool_choice="required"` 代表必须基于真实工作区做判断
- structured output 加 artifact 写盘，才让结果真正可消费、可落地
- eval 契约让这个项目从 demo 走向可回归系统

## 易错点

- 容易把它理解成“写一个 code review prompt”的教程
- 容易把 `AGENTS.md` 当成普通说明文件，而忽略它在这里其实是行为约束的一部分
- 容易忽略结构化输出和 artifact，只有自然语言总结不足以支撑后续程序消费和回归评估
- 容易低估 eval 契约的重要性，没有 contract，审查结果很容易停留在主观感受层

## 我的理解

这个项目最值得复用的，不是某条 prompt，而是它的工作流骨架：固定输入仓库、通过工具接触真实工作区、输出结构化结果、落盘 artifact、再用 eval 校验 contract。

如果要做一个可回归的审查型 agent，这套骨架比单次审查效果更重要。

## 相关笔记

- [[项目卡：sandbox vision_website_clone 工作流]]
- [[OpenAI Agents SDK 示例与学习路径]]
- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
