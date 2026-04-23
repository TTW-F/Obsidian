---
tags:
  - 主题
  - OpenAI Agents SDK
  - Sandbox
  - Vision
  - 前端
  - 项目
type: note
source: E:\AI_Writer\vendor\openai-agents-python\examples\sandbox\tutorials\vision_website_clone
---

# 项目卡：sandbox vision_website_clone 工作流

## 这张卡在讲什么

这个 tutorial 展示的不是通用网页生成，而是一个非常窄但非常典型的视觉型 sandbox 工作流：

1. 读取一张参考截图
2. 在 sandbox 里写静态 HTML/CSS
3. 用浏览器截图检查结果
4. 再根据截图继续修正
5. 最后把生成站点和视觉调试产物复制回宿主

所以它更像一个“视觉复刻 agent”的最小模板。

## 1. 这个项目的目标故意很窄

README 一开始就强调了：

- 这是 narrow UI repro target
- 不是 web-app scaffold
- 不启动本地浏览器服务
- 不做 FastAPI

这点很重要，因为它说明作者在刻意把问题收窄成：

“给定视觉参考，把可见界面还原成静态前端产物。”

也正因为目标窄，视觉调试流程才更容易被看清。

## 2. 输入设计极简但很有效

manifest 只挂了三样东西：

- `AGENTS.md`
- `reference/reference-site.png`
- `output/`

这意味着整个任务的输入几乎全部围绕那一张参考图展开。

这和 `repo_code_review` 的“挂整个仓库”完全不同，也很好地说明了：

- sandbox 并不只适合代码仓库任务
- 它同样适合文件驱动、视觉驱动的长任务

## 3. `AGENTS.md` 是这类视觉任务的主流程控制器

这个示例里的 `AGENTS.md` 写得非常流程化，甚至比 code review 那张更强流程导向。

它明确要求 agent：

- 第一件事就 `view_image`
- 先写 `visual-notes.md`
- 再生成 `output/site/index.html` 和 `styles.css`
- 再加载 `playwright` skill
- 必须拍 `draft-1.png`
- 看完后继续修
- 再拍 `draft-2.png`

这说明视觉型 agent 的关键不只是“会看图”，而是：

“把视觉检查和修订回路写进任务契约。”

## 4. 这是一个典型的视觉调试闭环

我会把它总结成下面这条链：

1. `view_image(reference)`
2. 先写视觉观察笔记
3. 生成第一版静态站点
4. 用浏览器截图产出 `draft-1.png`
5. 再 `view_image(draft-1.png)` 做差异比对
6. 修改站点
7. 再拍 `draft-2.png`

这和普通“生成网页”最大的差异就在于：

- 它把 screenshot critique loop 变成了工作流核心

## 5. 为什么这个项目一定要 `view_image`

README 和 `AGENTS.md` 都把这一点写成 required workflow。

这是因为对这类任务来说，真正的 grounding 不是仓库文件，而是视觉参考本身。

如果没有 `view_image`，模型只能靠 prompt 猜界面。

所以这类视觉型 sandbox 任务的 grounding 入口是：

- 图像理解

而不是：

- 仓库阅读

## 6. skill 懒加载的用法也很有代表性

这个案例还有一个很值得借鉴的点：

- `Skills(lazy_from=LocalDirLazySkillSource(...), skills_path="skills")`

也就是说：

- 并不是启动时就把全部 skill 全塞进 sandbox
- 而是让 agent 在需要的时候 `load_skill("playwright")`

这特别适合视觉/前端类任务，因为：

- 浏览器自动化不一定每次都要用
- 但一旦需要，就可以显式拉起

这是一种很工程化的 capability 供给方式。

## 7. 输出设计也分成两层

这类任务最后的产物不是只有网页文件。

它会把 sandbox 内部生成的内容复制回宿主：

- `index.html`
- `styles.css`
- `screenshots/draft-1.png`
- `screenshots/draft-2.png`
- `visual-notes.md`

这说明视觉型工作流的真实输出往往有两类：

- 最终成品
- 中间复盘证据

后者在视觉任务里尤其重要，因为它能让人直接看到 agent 是怎么逐步逼近参考图的。

## 8. 这个项目为什么也用 streamed run

和 code review 一样，这里也用了 `Runner.run_streamed(...)`。

原因也很类似：

- 任务不是一次性文本生成
- 中间会发生多轮观察、编辑、截图、再观察

所以 streamed run 在这里不仅是“更好看日志”，而是更贴合视觉迭代任务本身的节奏。

## 9. `tool_choice="required"` 在这里的意义

这个设置在视觉任务里同样关键。

因为如果 agent 不真正调用：

- `view_image`
- shell / filesystem
- skill 里的浏览器能力

那它就只能靠想象输出一个网页。

而这个 demo 的价值就在于证明：

- 视觉型任务也可以被严格 grounded in tools

## 10. 和 `repo_code_review` 的对照很有价值

我会这样对照这两个项目卡：

### `repo_code_review`

- 输入是 git repo
- 核心 grounding 是 shell + file inspection
- 输出是结构化 review + patch
- eval 更偏 contract 检查

### `vision_website_clone`

- 输入是 reference screenshot
- 核心 grounding 是 `view_image` + browser screenshots
- 输出是静态站点 + 视觉调试产物
- eval 更偏人工视觉检查

这说明 sandbox tutorial 不是只有一种工作流形态，而至少覆盖了：

- 代码/仓库型
- 视觉/界面型

两种典型范式。

## 11. 我对这个项目的一句话理解

它是一个“把视觉参考复刻任务产品化”的最小 sandbox 模板。

## 12. 这个项目最值得借鉴的结构

### 输入层

- 参考截图
- 明确的视觉工作规程

### 运行层

- `view_image`
- `Filesystem`
- `Shell`
- 懒加载 `playwright` skill
- 截图复盘循环

### 输出层

- HTML/CSS 成品
- 两轮草稿截图
- visual notes

## 13. 适合什么时候看这个项目

它最适合放在：

- 已经理解 sandbox 基础能力
- 已经懂 `view_image`
- 想看一条非代码仓库型工作流

之后。

如果你主要关心 coding/review 类任务，可以先看 [[项目卡：sandbox repo_code_review 工作流]]。
