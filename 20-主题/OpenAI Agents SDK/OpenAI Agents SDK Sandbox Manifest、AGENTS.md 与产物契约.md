---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Manifest
  - AGENTS
  - Artifact
  - 源码
type: note
---

# OpenAI Agents SDK Sandbox Manifest、AGENTS.md 与产物契约

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK sandbox tutorial 里一条很容易被忽略、但非常关键的工作流主线：

- `Manifest` 决定工作区里有什么
- `AGENTS.md` 决定 agent 在工作区里该怎么做
- host 侧 wrapper 决定哪些产物必须被带回宿主、怎么校验

如果只盯着 user prompt，很容易把这些 tutorial 看成“换个 prompt 跑一下 agent”；但从 `examples/sandbox/tutorials/` 的实现看，真正固定工作流的是这三层契约。

## 为什么重要

- sandbox agent 的稳定性，往往不取决于 prompt 多华丽，而取决于工作区输入、流程约束和产物出口是否被写死
- 这条线能解释为什么 tutorial 看起来像“产品切片”，而不只是零散 demo
- 它也能帮助我区分三种不同东西：运行环境、工作规程、最终交付

## `Manifest` 为什么是工作区输入契约

`src/agents/sandbox/manifest.py` 里，`Manifest` 的核心字段包括：

- `root`
- `entries`
- `environment`
- `users` / `groups`
- `extra_path_grants`
- `remote_mount_command_allowlist`

其中最关键的是 `entries`。

因为 tutorial 真正带进 sandbox 的文件、目录、挂载仓库和参考资料，都是在这里声明的。

例如：

- `repo_code_review` 把 `AGENTS.md` 和一个 pinned `GitRepo(...)` 挂进去
- `vision_website_clone` 把 `AGENTS.md`、参考截图和空的 `output/` 目录挂进去

所以 `Manifest` 不是“附件列表”，而是 agent 开始工作前的输入边界。

## `AGENTS.md` 为什么是工作规程契约

在两个 tutorial 的 `main.py` 里，`AGENTS.md` 都不是仓库里预先存在的静态文件，而是由 Python 字符串常量生成，再通过 `Manifest(entries=...)` 写进 sandbox。

这一步很值得记住，因为它说明：

- `AGENTS.md` 可以是随 tutorial 一起编排的运行时契约
- 它既能被挂进工作区，也能同时作为 `SandboxAgent.instructions`

在 `repo_code_review` 里，`AGENTS.md` 约束的是：

- 必须跑哪条测试命令
- findings 只能命中哪两个文件
- 不要评论哪些文件
- `fix_patch` 必须是什么样的最小 diff

在 `vision_website_clone` 里，`AGENTS.md` 约束的是：

- 第一件事先 `view_image`
- 先写 `visual-notes.md`
- 必须加载 `playwright` skill
- 必须拍 `draft-1.png` 和 `draft-2.png`

这说明 `AGENTS.md` 的作用不是“再重复一遍 prompt”，而是把工作流步骤、硬约束和交付要求写进 agent 的默认行为层。

## 产物契约为什么通常写在 host wrapper 里

tutorial 的另一个关键点是：最终交付什么，并不只靠 agent 自觉完成，而是由 `main.py` 在 host 侧进一步固定。

`repo_code_review/main.py` 里：

- 先要求 `output_type=RepoReviewResult`
- 再由 `write_review_artifacts()` 把结果拆成 `review.md`、`findings.jsonl`、`fix.patch`

`vision_website_clone/main.py` 里：

- agent 在 sandbox 内写 `output/site/`、`output/screenshots/`、`output/visual-notes.md`
- host 再调用拷贝函数把文件复制回宿主
- 最后检查 `index.html` 和 `styles.css` 是否真的生成

所以 tutorial 真正的产物契约，往往是“agent 产出 + host 校验 + 宿主持久化”三者一起完成的。

## 为什么 `output_type` 和文件产物是两条不同交付线

`repo_code_review` 很能说明这一点。

它既有：

- typed final output：`RepoReviewResult`

又有：

- 文件产物：`review.md`、`findings.jsonl`、`fix.patch`

这说明 sandbox 工作流里的“最后结果”并不总是单一形态。

更常见的情况是同时存在两条线：

- 一条给程序消费的结构化结果
- 一条给人或后续系统处理的 artifacts

## tutorial 的稳定性为什么来自窄契约

从两个 tutorial 看，作者都在故意把目标收窄。

例如：

- `repo_code_review` 明确限定 findings 数量、目标文件和 patch 改动范围
- `vision_website_clone` 明确限定只复刻单个 screen、必须进行两轮截图复盘

这类窄契约的意义是：

- demo 更可复现
- 输出更可校验
- 例子更像可回归工作流，而不是开放式探索

## 一个具体场景怎么理解这三层契约

如果一个 sandbox agent 只拿到 user prompt，却没有固定 Manifest、没有 AGENTS.md、也没有 host 侧产物校验，那么它很可能只是“一次性完成一个看起来像的任务”。

而当这三层都写稳之后，同一条工作流就会从 prompt 实验升级成可复现、可校验、可交付的产品切片。

这个场景能帮助我记住：sandbox tutorial 真正稳的地方，不在 prompt，而在契约。

## 最该记住的点

- `Manifest` 固定输入边界
- `AGENTS.md` 固定工作规程
- host wrapper 固定交付和校验
- typed final output 和文件 artifacts 通常是两条不同交付线
- 窄契约会让 tutorial 更像可回归系统，而不是开放式 demo

## 易错点

- 容易把 sandbox tutorial 的关键理解成 user prompt
- 容易把 `AGENTS.md` 看成静态仓库文件，但在这些 tutorial 里它其实是运行时生成的
- 容易把 final output 和 artifact 混成一类交付
- 容易低估“窄契约”的价值，以为约束多会削弱 demo

## 我的理解

OpenAI Agents SDK 的 sandbox tutorial，最值得学的不只是某个 agent 会不会用 shell 或 `view_image`，而是它怎样把一条工作流拆成三层契约：

- `Manifest` 固定输入边界
- `AGENTS.md` 固定工作规程
- host wrapper 固定交付和校验

只要这三层写稳，sandbox agent 就更像一个能被产品化的工作流，而不是一次性 prompt 实验。

## 相关笔记

- [[OpenAI Agents SDK Sandbox、MCP 与扩展生态]]
- [[项目卡：sandbox repo_code_review 工作流]]
- [[项目卡：sandbox vision_website_clone 工作流]]
