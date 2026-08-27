---
title: 架构边界：原生 vs 新增 vs 改造
tags: [架构, 边界, 入门]
links: ["00 项目导航 MOC", "03 分层架构与包地图"]
created: 2026-08-28
---

> [!info] 给迷路的自己
> 这个仓库是 **OpenCode 的 fork**。最大的困惑来自：OpenCode 的原生代码和我们后来加的代码混在同一个 monorepo 里。
> 本文给你一条**一眼区分**的规则 + 三色清单 + 已验证的依赖方向证据。

---

## 一、一句话区分法（最重要）

**看包名（目录名）就够了：**

- 包名带 `novel-` 前缀，或目录是 `apps/novel-web`、`templates/work-skeleton` → **我们的代码**。
- 其他所有包（`core` / `opencode` / `server` / `sdk` / `sdk-next` / `schema` / `protocol` / `client` / `app` / `tui` / …）→ **OpenCode 原生（fork 底座）**。

不需要去读内部实现，看它在哪个包，立刻就知道归属。

---

## 二、三色清单

### 🟦 蓝：OpenCode 原生负责（底座引擎，我们基本不改内部逻辑）
这些包来自 OpenCode，提供通用能力。我们**复用**，不重写：

- `packages/core` — 基础设施：git、session/transcript、PermissionV2、SystemContext/InstructionContext、Location、Project、Config、工具系统底座。
- `packages/opencode` — 会话编排、指令挂载（`session/instruction.ts`）、Event V2、provider/LLM 运行时。
- `packages/server` — OpenCode 自带的服务端（通用 HTTP handler，如 permission 路由）。
- `packages/sdk` / `packages/sdk-next` / `packages/sdk-js` — **公开 SDK**。其中 `sdk-next` 是"进程内嵌入 OpenCode"的入口，我们的桥接只通过它驱动底座。
- `packages/schema` / `packages/protocol` / `packages/client` — 类型与协议、客户端。
- `packages/app` / `packages/tui` / `packages/cli` / `packages/ui` / `packages/web` / `packages/desktop` / … — OpenCode 自带的应用/界面外壳。
- 其余通用包：`llm`、`identity`、`plugin`、`enterprise`、`stats`、`slack`、`session-ui`、`storybook`、`codemode`、`console`、`containers`、`http-recorder`、`httpapi-codegen`、`effect-drizzle-sqlite`、`effect-sqlite-node` 等。

**蓝区负责什么（具体）：**
git 操作、会话与转录、PermissionV2 **运行时强制**、AGENTS.md/SystemContext **自动挂载**、SSE / Event V2、工具系统、provider/LLM 调用、MCP、配置。

---

### 🟩 绿：我们新增的领域 + 桥接 + 前端（100% 我们的）
包名带 `novel-`，或 `apps/novel-web`、`templates/`：

- `packages/novel-core` — 领域层：
  `WorkGit`（作品 git 封装）、`WorkLayout`（作品骨架目录）、
  `role.ts` / `WRITE_SCOPE`（六角色 + 目录限域）、`role-permissions.ts`、
  `commit-service`（唯一提交门面）、`search-index`（每作品 SQLite 检索）、
  `work-repository`、`work-record`、`workbench` 投影、`agent-crew` / `agent-seat`、
  `session-host`（桥接宿主）、`gateway-run-bridge`、`command-idempotency`（命令幂等）、
  `composer-prefs`、`WritingEvaluation`（写作评测）等。
- `packages/novel-server` — 运行时/桥接层：
  `runtime/opencode/adapter.ts`（桥接）、`delegation-flow.ts`、`event-mapper.ts`、
  `sse-hub.ts`、`run-map.ts`、`drain-admission.ts`、`startup-reconciliation.ts`、
  `workbench.ts`、`agent-gateway-routes.ts`、`work-search.ts`、`work-index-sync.ts`。
- `apps/novel-web` — 前端：
  `agent-chat/projection.ts`、`use-agent-conversation.ts`、`sse-connection.ts`、
  `event-adapter.ts`、`three-pane-linkage`，以及约 70 个 `*-projection.ts`。
- `templates/work-skeleton` — 每个作品初始化时播种的 `AGENTS.md` + `memory/*.md`。

---

### 🟧 橙："改造/加固"的真相（最让人困惑的部分）

你担心的"到底哪些被改了"，答案分两层：

**1）架构上的"改造"几乎不是改 OpenCode 源码，而是加桥接。**
已用 grep 验证（见下）：OpenCode 的所有包**从不** `import @opencode-ai/novel-*`（0 处）。
依赖方向是**单向**的：`novel-* → @opencode-ai/sdk-next`（公开 SDK）。
这是"反污染层"设计（不变量 3.8 复用优先）。我们的做法：
- 在 `novel-server` 里写桥接（`session-host` 用 `sdk-next` 把 OpenCode 进程内嵌入）；
- 通过 `.opencode/agents` 定义承载 PermissionV2 规则；
- 业务语义（六角色、作品 git、检索）全写在 `novel-*` 里。

**2）但 `core` / `opencode` 确实是 fork，历史里有我们提交的通用增强补丁。**
git log 可见：`feat(core): integrate MCP tooling, session-tools, and config`、`feat(opencode): ...` 等。
这些补丁让底座更通用、支持 novel 需求，但**仍留在 OpenCode 包内部、保持通用、且不反向依赖 novel**。
所以"被改过的 OpenCode 文件" = 这些 `feat(core)` / `feat(opencode)` 提交触及的文件。

> [!warning] 诚实边界
> 当前仓库只有我们自己的 fork remote（`TTW-F/AI_Novels_Opencode`），**没有挂 OpenCode 上游 remote**，
> 因此我**现在无法给你逐文件的"改造清单"**（需要把上游拉下来做 diff 才能精确列出）。
> 本文能给的是：**包级边界（100% 准确）+ 单向依赖证据（已验证）**。
> 如果你要逐文件清单，我可以：(a) 加 OpenCode 上游 remote 并 diff；或 (b) 你提供上游 tag，我来比。

---

## 三、已验证的依赖方向证据

- 在 `packages/` 全量 grep `from "@opencode-ai/novel..."`：**54 处匹配，全部位于 `packages/novel-server` 内部**（我们的代码依赖我们的 `novel-core`，正常）。
- OpenCode 包（`core`/`opencode`/`server`/…）反向依赖 novel 的次数：**0**。
- `novel-server/src` 里 `import ... from "@opencode-ai/sdk-next"` 出现 **13 处**（`session-host`、`adapter`、`delegation-flow`、`event-mapper`、`run-map`、`startup-reconciliation`、`agent-crew`、`work-tools` 等）——即我们的桥接统一通过公开 SDK 驱动底座。

结论：**OpenCode 是黑盒底座，novel 是外包了一层桥接与领域的"套壳"系统，二者通过 SDK 单向连接。**

---

## 四、最小心智模型

> 把 OpenCode 想成"一台现成的车"（引擎、变速箱、方向盘都好了）。
> 我们的 `novel-*` 不是拆开发动机重造，而是在车外**加装货箱、导航、调度系统**，并通过车厂给的**标准接口（sdk-next）**去踩油门、读仪表。
> 所以：车里的东西（蓝）= OpenCode 原生；加装的货箱导航（绿）= 我们的；
> "改造"= 我们偶尔给车厂提了几个通用零件补丁（橙），但没动发动机，也没让车反向依赖我们的货箱。

---

## 五、快速自查清单

看到一段代码，问自己三句：
1. **它在哪个包？** `novel-*` / `novel-web` / `templates` → 我们的；否则 → OpenCode 原生。
2. **它在 import 谁？** 我们的代码 import `@opencode-ai/sdk-next` 是正常的（桥接）；OpenCode 代码 import `novel-*` 是不存在的（若看到，是严重架构违规）。
3. **它做的是"通用引擎能力"还是"小说领域业务"？** 前者归蓝，后者归绿。
