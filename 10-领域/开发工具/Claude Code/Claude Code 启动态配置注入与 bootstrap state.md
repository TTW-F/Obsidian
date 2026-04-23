---
tags:
  - 领域
  - 开发工具
  - Claude Code
  - bootstrap
  - state
  - 配置
  - 源码分析
type: area
---

# Claude Code 启动态配置注入与 bootstrap state

## 这是什么

这篇笔记整理的是 Claude Code 启动阶段那些“不直接跑主循环，但决定会话长什么样”的注入链。

如果只看 `src/bootstrap/state.ts`，很容易觉得它只是一个 getter/setter 大仓库。更有用的理解方式是：

它是启动期会话元数据的集中寄存层，负责把 CLI flag、remote/direct-connect 上下文、认证材料和部分运行模式信息，先稳定放进全局 state，再由其他模块读取。

## 为什么重要

- 它解释了 Claude Code 为什么能在很早阶段就决定 settings 来源、remote 模式、direct connect 标识和会话鉴权
- 这层虽然不直接执行业务，但会影响后面几乎所有 settings、remote transport、header 显示和认证分支
- 如果不先看这条注入链，很多后续模块会显得像“凭空知道”当前会话处于什么模式

## 先记住 bootstrap state 的定位

`bootstrap/state.ts` 里存的不是业务模型，而是会话级启动状态。

这类状态有几个典型特征：

- 很早就要可读
- 会被很多模块跨层读取
- 不适合等 React tree 或 QueryEngine 起起来以后再初始化

我现在会把它看成四类注入槽位：

- settings 相关
- remote / direct connect 相关
- 认证材料相关
- session 级开关和运行模式相关

## 第一条链: `--settings` 和 `--setting-sources` 的早期注入

这条链主要发生在 `main.tsx` 里，而且刻意比 `init()` 更早。

### `--settings`

`main.tsx` 的 `loadSettingsFromFlag()` 会：

- 接受文件路径，或者一段内联 JSON
- 如果是内联 JSON，先写到一个稳定的临时文件
- 调 `setFlagSettingsPath()`
- 再 `resetSettingsCache()`

这样后面的 settings 读取就能把 flag settings 当成正式来源之一。

### `--setting-sources`

`loadSettingSourcesFromFlag()` 会：

- 用 `parseSettingSourcesFlag()` 解析用户允许的来源
- 调 `setAllowedSettingSources()`
- 再 `resetSettingsCache()`

这里最关键的配套在 `utils/settings/constants.ts`：

- `getEnabledSettingSources()` 会永远把 `policySettings` 和 `flagSettings` 加回去

也就是说，用户可以裁掉：

- user
- project
- local

但裁不掉：

- flag
- managed / policy

这很像一种启动时的“可读来源白名单”。

## 第二条链: headless / SDK 控制通道里的内联 flag settings

`cli/print.ts` 里还有一条很重要的注入链。

当控制消息 `apply_flag_settings` 到来时，它会：

- 读取当前 `getFlagSettingsInline()`
- 和新传入 settings 做浅合并
- 把 `null` 转成删除
- 调 `setFlagSettingsInline(merged)`
- 通过 `settingsChangeDetector.notifyChange('flagSettings')` 扇出

这说明 Claude Code 的 flag settings 不只有启动参数一种入口。

在 headless / SDK 场景里，它还能被运行中更新，而且更新后会：

- 刷 settings cache
- 触发 settings 变更订阅者
- 必要时连 model override 一起更新

所以 `flagSettingsPath` 和 `flagSettingsInline` 分别服务两类场景：

- path: 启动时一次性载入
- inline: 会话中动态注入

## 第三条链: remote / direct connect / ssh 模式注入

这条链主要也在 `main.tsx`。

### Direct Connect

对 `cc://` 或 `claude connect`，启动链会：

- 先把 URL 和 token 暂存在 `_pendingConnect`
- 调 `createDirectConnectSession()`
- 如果远端回了 `workDir`，就更新 `originalCwd` 和 `cwd`
- 调 `setDirectConnectServerUrl()`
- 把返回的 `config` 交给 REPL

这里 `directConnectServerUrl` 更像会话标识和展示信息，不是 transport 本体。现有代码里它会被 `logoV2Utils.ts` 读取，用来在 header 里显示当前连的是哪个 server。

### SSH

SSH 代理模式走的是不同后端，但也会调：

- `setDirectConnectServerUrl(_pendingSSH.local ? 'local' : _pendingSSH.host)`

这说明 `directConnectServerUrl` 在心智上已经被复用成“当前外部会话终点”的显示槽位，而不只是 direct connect 专用字段。

### Remote

无论是 assistant viewer 还是 `--remote` 创建的 CCR 会话，都会先：

- `setIsRemoteMode(true)`

然后再创建 `remoteSessionConfig`，交给 REPL 使用。

所以 `isRemoteMode` 的作用也更偏“让后续模块知道当前会话属于远端执行形态”，而不是直接承载连接本身。

## 第四条链: session ingress token 注入

`utils/sessionIngressAuth.ts` 负责处理 Claude Code Remote 里很关键的一类凭证: session ingress token。

它的优先级是：

1. `CLAUDE_CODE_SESSION_ACCESS_TOKEN`
2. 文件描述符
3. well-known file

而 `bootstrap/state.ts` 在这里承担的是缓存槽位：

- `sessionIngressToken`
- `setSessionIngressToken()`

这样做的原因很实际：

- 文件描述符通常只能读一次
- subprocess 不一定继承得了 FD
- 所以需要有进程内缓存，也需要必要时落到 well-known file 给子进程续用

这条链本质上是在解决“远端会话身份怎样进入当前 CLI 进程并向子进程延续”。

## 第五条链: OAuth token / API key 的 FD 注入

`utils/authFileDescriptor.ts` 处理另外两类凭证：

- OAuth token
- API key

它们同样会先尝试：

- 读 FD
- 失败后回退到 well-known file

然后把值写进：

- `oauthTokenFromFd`
- `apiKeyFromFd`

这些字段并不是对外常规 auth API，而是专门给 CCR 这类受控环境做凭证搬运和缓存。

## remote managed settings 和 bootstrap state 的关系

这一点也值得单独记一下。

`remoteManagedSettings/index.ts` 并不直接往 `bootstrap/state.ts` 里塞 managed settings 内容，但它会受启动期来源控制影响：

- `allowedSettingSources`
  - 决定用户 / project / local 是否启用
- `policySettings`
  - 在 `getEnabledSettingSources()` 里永远会被包含

所以 bootstrap state 更像是 settings 系统的“入口闸门”，而不是 managed settings 的存储层。

## `bootstrap/state.ts` 为什么会长成 getter/setter 仓库

如果只看文件形态，它确实像一个很厚的全局状态文件。

但换个角度看，这其实是在做一件很朴素的事：

- 把启动期的跨层依赖集中到一个地方
- 避免各模块自己去解析 CLI 参数、读 FD、猜当前模式
- 让 `main.tsx`、`cli/print.ts`、auth/remote/settings 模块之间只通过少量稳定槽位传递上下文

我觉得它更像启动期的共享会话寄存器，而不是通用状态管理层。

## 易错点

- 容易把 `bootstrap/state.ts` 当成业务中心，实际上它更多是会话级元数据寄存层
- 容易把 `flagSettingsPath` 和 `flagSettingsInline` 当成重复字段，实际上它们分别服务启动载入和运行中注入
- 容易把 `directConnectServerUrl` 理解成传输配置本体，实际上当前更接近“外部会话端点显示信息”
- 容易忽略 session ingress token / auth FD 这类字段的存在背景是 CCR 子进程和受控环境

## 我的理解

Claude Code 启动链有一个很明显的取向：

先把“这是谁的会话、从哪来、允许读哪些设置、当前是不是远端、凭证从哪里拿”这类问题，在真正起主循环之前解决掉。

`bootstrap/state.ts` 正是这套取向的收口点。

它不负责把功能做出来，但负责让后面的功能不用再重复决定运行前提。

## 相关笔记

- [[Claude Code 启动链路与运行模式]]
- [[Claude Code Direct Connect 会话入口]]
- [[Claude Code Bridge、Remote 与 IDE 集成]]
- [[Claude Code Voice 输入、转写与语音交互链路]]
- [[../../40-源码镜像/AI_Writer Vendor/Claude Code 目录到笔记映射]]
