---
tags:
  - 主题
  - OpenAI Agents SDK
  - 示例
type: note
---

# OpenAI Agents SDK 示例与学习路径

## 第一层：最小可运行

先看 `examples/basic/`：

- `hello_world.py`
- `tools.py`
- `stream_text.py`
- `tool_guardrails.py`
- `usage_tracking.py`

这一层的目标是先把 `Agent + Runner + tool` 的最小闭环跑通。

## 第二层：常见 agent 模式

`examples/agent_patterns/README.md` 总结得很清楚，值得重点吃透：

- deterministic flow
- routing
- agents as tools
- parallelization
- guardrails
- human in the loop

这一层最适合拿来和源码层概念建立映射。

## 第三层：状态、外部工具与 provider

- `examples/memory/`
- `examples/mcp/`
- `examples/model_providers/`

这一层对应的是“从 demo 进入真实工程”的三个维度：

- 多轮状态
- 工具外接
- 模型替换

## 第四层：Sandbox

建议顺序：

1. `examples/sandbox/basic.py`
2. `examples/sandbox/sandbox_agent_with_tools.py`
3. `examples/sandbox/sandbox_agents_as_tools.py`
4. `examples/sandbox/memory.py`
5. `examples/sandbox/unix_local_runner.py`

这是从“普通 agent”升级到“工作区 agent”的关键跃迁。

## 第五层：完整工作流示例

如果要看更像真实系统的组织方式，优先看：

- `examples/research_bot/`
- `examples/financial_research_agent/`
- `examples/customer_service/main.py`

这几组示例适合观察：

- manager / planner / writer / verifier 的角色拆分
- 多 agent 如何串起来
- 最终输出如何整理

## 我给自己的学习路线

第一阶段：`basic + quickstart`  
第二阶段：`agent_patterns`  
第三阶段：`running_agents + sessions + tracing`  
第四阶段：`sandbox + mcp + model_providers`  
第五阶段：`realtime + voice + experimental/codex`
