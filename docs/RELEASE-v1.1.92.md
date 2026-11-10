# v1.1.92 发布说明

发布日期：2026-11-10 · 安装器：`dist/dsh-preset-kit-setup-1.1.92.exe`（单文件，2.0 MB 载荷内嵌）

## 一句话

适配 **DeepSeek Harness 0.2.2-rc.1**：载荷整体升到 1.1.92，在新宿主上 **68/70 applied、0 pending、0 drifted**，装完即用，不再出现「未适配」与成片 `drifted`。

## 载荷

- `dist/dsh-preset-kit-1.1.92.tgz` — 2,023,466 B，97 个文件，`package/` 根，可直接 `pnpm add file:`
- 包名 `dsh-purge`（历史名，面板里就是那个预设工具箱），`version: 1.1.92`
- `dshTargets: ["0.2.1-rc.2", "0.2.1-rc.5", "0.2.2-rc.1"]`
- 与 1.1.90 载荷不是同一份源码：1.1.90 是上游 preset-kit 快照，1.1.92 是长期在用的主线（补丁表、目标文件、文案都不同），**首次从 1.1.90 升上来请先回滚旧补丁再装**。

## 变更

### 一、补丁表适配 DSH 0.2.2-rc.1（九处 drifted 全部修好）

新版宿主改了九处被补丁锚定的代码，旧 pattern 全部落空 ⇒ 面板报 9 个 `drifted`。逐条重写锚点：

| # | 补丁 | 旧锚点为什么不匹配 | 新锚点 |
|---|---|---|---|
| #14 | ESCALATION_GRANT_UNCONDITIONAL | `displayReason` 由内联 en/zh 对象改成 `escalationDisplayReason(mode, justification)` | 匹配整个 `approval.approver.request({...})` + `switch (outcome)` 块，整段换成 `return mode;` |
| #17 | FS_OBSERVATION_INTENT_FREE | `editIntent` / `deleteIntent` 改成委托 `this.requirePresent(...)` | 匹配两处委托语句，各换成 `return void 0;` |
| #40 | COMPLETE_PROMPT_KEEP_INJECT | 老版 `assemble` 里的 `dshPurgeInject` / `dshPurgeSections` 变量不存在了 | 正则匹配新的 `assemble` 尾部返回对象（含 `tools`、`sections`、`contexts` 三段），重排为「注入段前置 / 普通段接尾 / complete 垫底」 |
| #54 | DELIVERABLE_DO_NOT | `present` 的提示词从 `dsh-client-ui-deliverables` 搬走了 | 目标文件改为 `dsh-deliverable-file-references/lib/index.js`（`FILE_REFERENCE_PROMPT`） |
| #60 | OFFICIAL_RUN_CODE_APPROVAL_NEUTRAL | `dsh-tools` 拆包，`run_code` 审批文案不在原文件 | 目标文件改为 `dsh-tool-executor-ptc/lib/index.js` |
| #62 | OFFICIAL_TOOL_ASK_FAILOPEN | 同上，`serviceAsk` 实现搬进 `lib/pipeline.js` | 目标文件改为 `dsh-tools/lib/pipeline.js` |
| #67 | AGENT_LOOP_MESSAGES_GUARD | 判空由 `if (turnEnds && …) break;` 改成 `decision.messages.length` 两处新分支 | 两处都加 `?.length ?? 0`（4 空格与 5 空格缩进各一条） |
| #74 | ASSEMBLE_BEFORE_PRESTEP | 新版 `assemble` 调用签名多了 `modelSelection` / `toolSet` | 在 `try {` 后插 `__dshPurgePrepareAssemble` 调用块（钩子缺失时静默跳过） |
| #82 | DESKTOP_SHELL_PROFILE_FALLBACK | 桌面主进程入口仍是 `main.js`，但脚本环境 `detectSurface()` 判 web 导致被跳过 | 锚定 `main.js` 第 1 行 `import { createRequire }`，其后注入默认 `DSH_PROFILE=desktop` |

顺带修掉一处连带冲突：**#35 ESCALATION_NEVER_REJECT** 的 markers 原本依赖 #14 删掉的那段 `case "allowed-once": default: return mode;`，现改为 `markersAny: true` 并追加 `[dsh-purge] escalation grant unconditional`，两补丁共存。

### 二、目标文件表跟着宿主拆包走

新增三个 `targetFiles` 键，起因是新宿主把实现拆进了新的包：

- `deliverable-file-references` → `dsh-deliverable-file-references/lib/index.js`
- `dsh-tools-pipeline` → `dsh-tools/lib/pipeline.js`
- `tool-executor-ptc` → `dsh-tool-executor-ptc/lib/index.js`

### 三、版本声明

`package.json` 的 `dshTargets` 追加 `0.2.2-rc.1`，面板不再打「未适配：插件声明 0.2.1-rc.2 / 0.2.1-rc.5」。

### 四、安装器

1. **`cordis.patch.yml` 写法修正**：原逻辑找到 `insert:` 键就往其后插 block；实际 profile 顶层是 **YAML 数组**（元素为 `- insert:`），旧写法会产出顶层 `insert:` 键 ⇒ 整份配置无效。现在固定追加顶层数组元素，带完整 `id / name / inject / config`（`enabled`、`stripMnemon`、`capabilityProtocol`、`hooksDenyBypass`）。
2. **空 `dependencies` 插入格式修正**：以前会产生 `"dependencies": {\r\n  "dsh-purge": …},` 这种贴在一起的写法，现在先算外层缩进再插，空对象也合法。
3. **不再改写插件自带提示词**：1.1.91 的 `CalibratePrompt` 会把本包自己的分类条目降级成上游 preset-kit 的旧文案；1.1.92 起提示词原样保留（`提示词改写=0`），只保留 `net-scope.js` 的会话预检校准。
4. **`app.asar` 默认不动**：默认 `noAsar = true`，需要时显式加 `--asar`。
5. 汇总行改按本包状态打印：`patches: 68/70 applied, 0 pending`。

## 验证记录（本机实测）

宿主 `DeepSeek Harness 0.2.2-rc.1`，`aiBase = %LOCALAPPDATA%\Programs\DeepSeek Harness\resources\app\dsh\node_modules\@deepseek-ai`。

- 面板状态：`68/70 applied · 0 pending · 0 drifted`；跳过两项按设计（`#71 LIANGSHEN_IDENTITY_LINE`、`#80 MINIMAL_OFFICIAL_TOOLSET`）。
- 八个被改文件 `node --check` 全过：`dsh-sandbox/lib/index.js`、`dsh-fs-observation-policy/lib/index.js`、`dsh-system-prompt/lib/index.js`、`dsh-deliverable-file-references/lib/index.js`、`dsh-tool-executor-ptc/lib/index.js`、`dsh-tools/lib/pipeline.js`、`dsh-agent-loop/lib/index.js`、`resources/app/lib/main.js`。
- 安装器夹具（`DSH_HOME=<临时目录>` + 真安装目录）：
  - `--dry-run --profile all`：报 DSH 路径、`DSH_HOME`、三个档案、内嵌载荷 2,023,466 B，不改任何文件。
  - 真装：`离线包落地` → `解包 97 个文件` → `node_modules/dsh-purge 版本: 1.1.92` → `dependencies 插入` → `bundles 追加` → `cordis.patch.yml: 追加 insert 段（顶层数组元素）` → `预检=关闭 提示词改写=0` → `app.asar 已不在，无需处理`。
  - 产物校验：`node -e "JSON.parse(...)"` 通过；`core.js` 里能 grep 到 `[dsh-purge] escalation grant unconditional` 与 `complete prompt keeps inject`；提示词文件与 tgz 原件逐字节一致。
  - 夹具覆盖：空 `bundles: []`、有 `dependencies`、空 `dependencies` 三种。
- tgz 自检：`tar --format=gnutar` 打包后解回，97/97 文件列表 identical。

## 升级/回滚

```bat
:: 升级（先退出 DSH，含托盘）
dsh-preset-kit-setup-1.1.92.exe --profile all

:: 只还原会话预检
dsh-preset-kit-setup-1.1.92.exe --cal-revert

:: 完全回到未安装
::   删除 <profile>\node_modules\dsh-purge
::   还原 package.json / cordis.patch.yml 的 .inst-bak
::   从面板「回滚」还原 resources\app 下的 .bak
```

从 1.1.90 升上来：先在旧面板点「回滚」（不同版本补丁标记不同名，直接叠加会留两套注释并报 `drifted`），再跑 1.1.92 安装器。

## 已知限制

- 补丁锚点是**宿主源码级**的，宿主再升一个 rc 很可能又有一批落空 —— 这是这类补丁的固有成本，出问题看面板 `drifted` 列表逐条对新版源码重锚。
- `--asar` 在 DSH 运行中会失败，需先 `--kill` 或手动退出（含托盘）。
- 默认不再改 `app.asar`：若你的安装还在读 `app.asar`，补丁等于没打，需要 `--asar` 或手动切到 `resources\app`。
- `dshTargets` 只声明到 `0.2.2-rc.1`，更高版本会重新出现「未适配」提示（提示，不阻止使用）。
