---
tags:
  - 主题
  - OpenAI Agents SDK
  - ModelSettings
  - 默认模型
  - 源码
type: note
---

# OpenAI Agents SDK 默认模型与 ModelSettings 合并规则

## 这是什么

这篇笔记整理的是 OpenAI Agents SDK 模型配置层里两件很基础、但很容易被忽略的事：

- 默认模型是怎么定的
- 一次 run 里的 `ModelSettings` 是怎么合并出来的

这两件事都落在源码里非常具体的位置：

- `src/agents/models/default_models.py`
- `src/agents/model_settings.py`

## 为什么重要

- 不理解默认模型规则，很容易误以为 SDK 对不同 GPT-5 变体的 reasoning 行为完全一样
- 不理解 `ModelSettings.resolve()`，就很难判断 agent 上的默认设置和本次调用 override 到底谁覆盖谁
- 这层虽然不在主循环中央，但会直接影响工具选择、并行工具调用、truncation 和响应载荷

## 默认模型到底怎么定

`default_models.py` 里的 `get_default_model()` 很直接：

- 先看 `OPENAI_DEFAULT_MODEL`
- 没配时默认回到 `gpt-4.1`

这说明 SDK 的“默认模型”不是写死在 agent 类里的，而是放在模型层统一决策。

## GPT-5 默认设置为什么不是一刀切

这个文件最值得注意的部分，不是默认模型名，而是 GPT-5 系列的默认 `ModelSettings`。

源码里预先定义了几组默认值，例如：

- `reasoning.effort="none"`
- `reasoning.effort="low"`
- `reasoning.effort="medium"`
- 只保留 `verbosity="low"` 的 text-only 默认

然后再按模型名模式去匹配。

例如源码里区分了：

- `gpt-5`
- `gpt-5.1`
- `gpt-5.2-pro`
- `gpt-5.3-codex`
- `gpt-5.4`

这说明 SDK 不是简单地把“GPT-5 = 开 reasoning”写成一条固定规则，而是在按具体模型族给默认 effort。

## 为什么 `chat-latest` 是特例

`gpt_5_reasoning_settings_required()` 里专门把 `gpt-5-chat-latest` 这类别名单独排除了。

也就是说：

- 某些 GPT-5 名字看起来属于同一族
- 但默认是否应该附带 `reasoning.effort`，源码是有特判的

这个细节很重要，因为它说明“模型名模式”和“是否自动补 reasoning 设置”并不是完全同一件事。

## `ModelSettings` 这个对象真正统一了什么

`model_settings.py` 里的 `ModelSettings` 集中承接了一次模型调用可能用到的大部分参数，例如：

- `tool_choice`
- `parallel_tool_calls`
- `truncation`
- `max_tokens`
- `reasoning`
- `verbosity`
- `response_include`
- `extra_headers` / `extra_body` / `extra_query`
- `retry`

可以把它先理解成模型调用层的统一配置面，而不是某个 provider 专属参数对象。

## `resolve()` 为什么是最值得记住的函数

`ModelSettings.resolve()` 是这层最关键的合并入口。

它的基本规则是：

- override 里非 `None` 的字段覆盖 inherited
- `extra_args` 不直接替换，而是做字典 merge
- `retry` 也不是整块替换，而是继续细分合并

所以这里的合并逻辑不是“后者整个覆盖前者”，而是字段级 overlay，遇到特殊字段再做定制规则。

## retry 为什么还有一层内部 merge

`_merge_retry_settings()` 和 `_merge_backoff_settings()` 又往下细拆了一层：

- retry 顶层字段按非 `None` 覆盖
- backoff 配置再继续按字段覆盖

这说明 retry 并不是一个黑盒 blob，而是可以被上层默认值和本次调用部分 override 的结构化配置。

## 一个具体场景怎么理解这层

如果某个 agent 自己带了一套默认 `ModelSettings`，而某次 run 又额外指定了：

- 不同的 `tool_choice`
- 更高的 `reasoning.effort`
- 特定的 retry 参数

运行时最终发出去的配置并不是简单“谁后写谁赢”，而是按字段逐层合并。

这个场景能帮助我记住：很多模型行为边界，其实不在 prompt 里，而在 `default_models.py` 和 `ModelSettings.resolve()` 这种合并逻辑里。

## 常见执行链怎么记

把这层放回主线里，可以先记成下面这条链：

1. 先确定 `model` 字符串，必要时回退到 `get_default_model()`
2. 再根据模型名取默认 `ModelSettings`
3. agent 或 run 级别的 `model_settings` 再与默认值合并
4. provider / model 适配层读取最终设置并翻译到底层请求

## 最该记住的点

- 默认模型不是 agent 自己随手决定的，而是由模型层统一给出
- GPT-5 默认 reasoning 不是一刀切，而是按模型模式细分
- `ModelSettings.resolve()` 不是简单替换，而是字段级 merge
- retry 和 backoff 也是结构化合并对象

## 易错点

- 容易以为 GPT-5 默认 reasoning 都一样
- 容易把 `ModelSettings.resolve()` 理解成简单替换
- 容易把默认模型看成 agent 的局部属性，而忽略它其实由模型层统一决定

## 我的理解

这层配置代码看起来不显眼，但它决定了 SDK 的默认行为是不是稳定、可预测。

尤其在 GPT-5、tool choice、并行工具调用和 retry 这些地方，真正的行为边界往往不是在 prompt 里，而是在 `default_models.py` 和 `ModelSettings.resolve()` 这种合并逻辑里。

## 相关笔记

- [[OpenAI Agents SDK 模型抽象层与 Provider 路由]]
- [[OpenAI Agents SDK 执行主线与源码入口]]
