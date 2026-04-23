---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - 代码审查
  - 项目
type: note
source: E:\AI_Writer\vendor\openai-agents-python\examples\sandbox\tutorials\repo_code_review
---

# 项目卡：sandbox repo_code_review 工作流

## 这张卡在讲什么

这个 tutorial 不是在教“怎么再写一个 code review prompt”，而是在演示一个完整的 sandbox 审查工作流闭环：

1. 挂载一个真实 git 仓库
2. 在隔离工作区里运行测试、读代码、看 diff
3. 以结构化结果返回 review findings
4. 把 review artifacts 持久化到输出目录
5. 用 eval 脚本校验结果是否符合契约

所以它更像一个最小可运行的“代码审查 agent 产品切片”。

## 1. 这个项目的目标故意很窄

README 里把 contract 说得非常明确：

- 必须返回恰好两个 findings
- 一个针对 `repo/.github/workflows/test.yml`
- 一个针对 `repo/src/sample/simple.py`
- patch 只允许修改 `simple.py`

这类“窄 contract”很重要，因为它让 demo 结果可评估、可回归，而不是完全开放式输出。

## 2. 输入设计非常干净

`main.py` 里的 manifest 只挂了两样东西：

- `AGENTS.md`
- 通过 `GitRepo(...)` 挂载的 `pypa/sampleproject` 指定提交

这背后的意义是：

- agent 有明确的工作规则来源
- 仓库输入是可复现、可固定的
- 每次跑 demo 的代码上下文都稳定

所以这不是“让 agent 随便审一个仓库”，而是故意收窄成一个可复现教程。

## 3. `AGENTS.md` 是核心工作契约

这个示例里，真正定义 agent 行为的重点不是 `question`，而是 `AGENTS.md`。

里面明确规定了：

- 要跑哪条测试命令
- findings 该对应哪两个文件
- 不要评论哪些文件
- 不要直接修改 mounted repo
- `fix_patch` 必须是什么样的最小 diff

这很值得记，因为它体现了 sandbox agent 的一个常见模式：

- 用户 prompt 给任务
- `AGENTS.md` 给硬约束和工作规程

## 4. 这个项目为什么适合 sandbox

因为它天然需要下面这些能力：

- 读真实仓库
- 跑测试命令
- 搜索文件
- 生成 patch
- 组织输出产物

这些事情如果没有 sandbox，往往就得自己拼：

- repo 暂存
- shell tool
- 文件系统工具
- artifact 写出
- 生命周期管理

这个 tutorial 的价值就在于，它把这些东西作为一个整体展示出来。

## 5. structured output 是这个项目的第二个核心

`main.py` 里定义了两个 Pydantic 模型：

- `ReviewFinding`
- `RepoReviewResult`

其中 `RepoReviewResult` 明确要求输出：

- `test_command`
- `test_result`
- `findings`
- `review_markdown`
- `fix_patch`

这表示这个工作流不是“让 agent 输出一段自然语言审查意见”而已，而是把 review 结果建模成程序可消费的数据结构。

这一步特别像产品化，而不只是 demo。

## 6. 产物写盘逻辑也很有代表性

`write_review_artifacts()` 会把结果拆成三类 artifact：

- `review.md`
- `findings.jsonl`
- `fix.patch`

这说明最终输出不是只有一个 `final_output`。

更常见的真实形态其实是：

- 人看的总结
- 机器读的 findings
- 可直接应用的 patch

这个 tutorial 很清楚地把三者分开了。

## 7. 流式运行很适合这类长任务

`main.py` 用的是 `Runner.run_streamed(...)`，并且逐个打印 stream events。

这很适合 code review 这类任务，因为它通常不是秒回型回答，而是：

- 先跑测试
- 再读代码
- 再形成判断
- 再组织输出

所以项目级 sandbox 工作流很常见的模式就是 streamed run，而不是一次性同步返回。

## 8. `tool_choice="required"` 很有意思

这个设置说明作者希望 agent 必须通过工具接触仓库，而不是只靠语言模型空想。

这和审查型任务很契合，因为：

- 不读文件、不跑测试的审查没有可信度

所以这个设置是在把“必须 grounded in workspace”写进模型行为层。

## 9. eval 脚本是这个项目最产品化的地方

`evals.py` 并没有做复杂 benchmark，但它已经足够说明思路：

- findings 数量必须是 2
- file path 必须精确命中目标文件
- workflow comment 必须提到 `nox` 和具体测试工具问题
- `simple.py` comment 必须提到 `add_one` 和 `-> int`
- patch 只能改 `simple.py`

这说明 sandbox tutorial 在教的不是“让 agent 看起来会做事”，而是：

“怎么把 agent 工作流变成一个有 contract、有 artifact、有校验的可回归系统。”

## 10. 我对这个项目的一句话理解

它是一个“把真实仓库审查任务产品化”的最小模板。

## 11. 这个项目最值得借鉴的结构

我会把它拆成下面几层：

### 输入层

- pinned repo
- `AGENTS.md`
- 明确 question

### 运行层

- `SandboxAgent`
- `Shell + Filesystem`
- streamed run

### 输出层

- structured final output
- markdown artifact
- jsonl findings
- patch artifact

### 评估层

- 用 `evals.py` 校验 contract

## 12. 适合什么时候看这个项目

它最适合放在：

- 已经理解 sandbox 和 structured output
- 想看一个更像真实产品切片的例子

之后。

如果还在最小阶段，先看前面的 basic / memory 案例更合适。

## 13. 后续可以怎么继续拆

- 把 `AGENTS.md` 里的规则单独抽成“审查型 agent 提示词模板”
- 对照 `healthcare_support` 看线性 workflow 和多 agent workflow 的差别
- 再补 `vision_website_clone`，形成“代码审查型”和“视觉复刻型”两种项目卡对照
