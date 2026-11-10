# v1.1.94 — 启动自愈 + 三条紧要补丁（适配 DSH 0.2.2-rc.1）

一句话：**DSH 官方升级再也不用手动重跑安装器了** —— 插件启动时发现宿主退回 `app.asar`，会自己在后台解包、重打补丁、预约改名，用户下次完全退出再打开就是「解包目录 + 全量补丁」。

## 载荷

| 项 | 值 |
|---|---|
| npm 包名 | `dsh-purge` |
| 版本 | 1.1.94 |
| 文件数 | 97（`package/` 根，去 `node_modules`） |
| tgz | `dsh-preset-kit-1.1.94.tgz` · 2,024,591 B · `809dd52adde4c2580fca4df5448bce727f268d25d54c54fdc2996ea26545028a` |
| exe | `dsh-preset-kit-setup-1.1.94.exe` · 2,063,872 B · `481b4d9c763ca122d67eea4f14a50ec214da800f7ba3b965063d0cf71fbe8a49` |
| `dshTargets` | `0.2.1-rc.2` / `0.2.1-rc.5` / `0.2.2-rc.1` |
| 补丁条数 | 89（1.1.92 是 86） |

## 变更

### 1. 启动自愈（核心）

新增配置 `healSealedOnStart`（默认 `true`），实现放在 `lib/index.js`：

```js
async function settleInstalledPatches(config, ctx, life) {
  // ...
  if (config.healSealedOnStart !== false) scheduleSealedHeal(config, ctx, life);
```

- `scheduleSealedHeal` 只在 `surface === "desktop"` 且 `core.desktopAsarStillSealed()` 为真时排程，**15 秒后**在后台跑（等官方 Host 的 `Fiber._reload` 结束，避免 `INACTIVE_EFFECT` 抢锁）。
- `runSealedHeal` 调 `reapply.reapplyInstalled({ upgrade: true })`：`openSealedDesktopHost` 按 `shouldExtractAsar({usable,identity,recorded,upgrade})` 判定要不要重解包 → `extractAsarToSide` → `overlayAsarUnpacked` → `commitExtractedDir` → `revertAll`（`freshExtract` 时跳过）→ `applyPatchesAllHosts` → `patchAllShims` → `markPatchesApplied` → `writeUnpackedAsarStamp`。
- 最后 `scheduleSealedDesktopRestart`：`renameAsarAside` 成功就直接改名；被占用就交给 `desktop.scheduleAsarRenameWhenIdle`（写 `<asar>.rename-pending` 锁 + `os.tmpdir()` 里的 detached PowerShell 脚本，等你退出后改名）。
- **不杀进程、不 `requestRestart`** —— 桌面端由官方 Host 管着 Fiber 生命周期，主动 kill 会撞 `INACTIVE_EFFECT`。下次启动即生效。
- 失败只写日志（`sealed heal: ok=false ...`），不阻塞启动、不重复执行（`sealedHealRunning` / `sealedHealDone` 双闸）。

### 2. 三条新补丁（86 → 89）

| # | 名称 | 目标文件 | 作用 |
|---|---|---|---|
| 94 | `ASK_USER_WAIT_CAPPED` | `dsh-tool-ask-user/lib/index.js` | `args.timeout === -1` 收成 300 秒。模型传 `-1` 求「无限等待」时，会话会一直挂到用户手动打断 |
| 95 | `COOKIE_NAME_IGNORE_PORT` | `dsh-client-connection/lib/index.js` | 会话 cookie 名对 `authority` 去掉 `:端口` 后缀。桌面端每次换随机端口就多一份 cookie，累积到请求头超过 8 KB 就被宿主回 431 |
| 96 | `HOST_MAX_HTTP_HEADER_SIZE` | `resources/app/lib/main.js` | 给 host 子进程加 `--max-http-header-size=262144`，兜住已经积累的历史 cookie |

补丁 96 的 pattern 是 `"--expose-internals",`（在 `main.js` 里唯一存在，host 子进程 `spawn(this.node, [...])` 的启动参数数组里），替换后紧跟一个 `"--max-http-header-size=262144"`。`markers` 为 `[dsh-purge] raise-host-header-limit`。

### 3. 两个新 targetFiles 键

`tool-ask-user`、`client-connection`（`lib/core.js` 的 `targetFiles()`，插在 `skill-badge` 之后）。0.2.2-rc.1 把 `ask_user` 的 timeout 收口与桌面会话 cookie 名拆到了独立插件，没有这两个键，94/95 必然 `nofile`。

### 4. 安装器

- 版本常量 `PkgVersion` / `ExeVersion` → `1.1.94`，内嵌载荷换成 `dsh-preset-kit-1.1.94.tgz`。
- 收尾提示改口径：`drifted = 0（1.1.94 共 89 条补丁，skipped 是设计内）`，不再写死 `68/70`。
- 其余沿用 1.1.93：内置 asar 解包、先试后杀改名、`--no-kill` / `--no-asar`、`install\build-exe.cmd` 的 `cd /d "%~dp0.."`。

## 验证记录（本机 DSH 0.2.2-rc.1）

安装器三场景夹具（`repo/test/test-194.ps1`，最小 5 文件 asar）：

| 场景 | 前置 | 结果 |
|---|---|---|
| A 全新电脑 | 只有 `resources\app.asar` | `[*] resources\app 不存在 → 首次解包` → `asar 解包：目录 1 个，文件 5 个（其中从 .unpacked 复制 1 个）` → `app.asar -> app.asar.dshpurge.bak（320 B）` → `asar: 已解包并切换到 resources\app` |
| B 老机器 | `resources\app` 已存在 + asar 仍在 | `[=] resources\app 已存在，跳过解包` → `[+] app.asar -> .bak` → `asar: asar 已改名，下次启动读解包目录`，原有 `app\package.json` 与 `app\lib\main.js` 原样保留 |
| C 幂等重跑 | asar 已改名 | `[=] app.asar 已不在（桌面端已跑在解包目录），无需处理` → `asar: 已在解包目录，无需处理` |

三个场景的 profile 接线都正确：`dependencies.dsh-purge = file:./.dsh-purge/dist/dsh-preset-kit-1.1.94.tgz`、`dsh.profile.bundles` 追加、`cordis.patch.yml` 追加顶层 `- insert:` 数组元素（含 `name` / `inject` / `config` 四项）。

生产环境（`resources\app` 解包目录 + 89 条补丁）：

- `node --check` 通过：`dsh-tool-ask-user/lib/index.js`、`dsh-client-connection/lib/index.js`、`app/lib/main.js`、`lib/core.js`、`lib/index.js`。
- 落盘 marker 核对：`#94` 在 `dsh-tool-ask-user/lib/index.js:181`、`#95` 在 `dsh-client-connection/lib/index.js:336`、`#96` 在 `app/lib/main.js:9982`。
- 补丁表统计（脚本口径）：89 条中 70 条 `applied`、0 `drifted`、0 `pending`；19 条 `nofile` 是 hooks / preset / liangshen / desktop-shell 类键在裸 node 下的路径解析限制（宿主内正常 `applied` 或设计内 `skipped`）。

## 升级 / 回滚

```bat
:: 升级：直接双击，装完等它自己重启
dsh-preset-kit-setup-1.1.94.exe

:: 只装插件、不动 asar
dsh-preset-kit-setup-1.1.94.exe --no-asar

:: 回滚到官方加载方式
ren "C:\Users\<你>\AppData\Local\Programs\DeepSeek Harness\resources\app.asar.dshpurge.bak" app.asar
```

插件层回滚：面板「回滚」还原所有 `.bak`；或 profile `package.json` 去掉 `dsh-purge` 依赖与 bundle 项后 `pnpm install`。

## 已知限制

- 自愈依赖插件本身还在 profile 里。如果 DSH 升级时把 profile 一起重置了，插件没了，就还是得重跑安装器。
- 自愈只在桌面端生效（`surface === "desktop"`）。web 面上没有 `resources\app` 这东西，`detectSurface` 也会跳过。
- 改名这一步永远是「下次启动生效」：`app.asar` 被运行中的进程锁着，只能等退出。`scheduleAsarRenameWhenIdle` 的锁文件 30 分钟过期，超时后下次启动会重排。
- 96 号补丁给 host 子进程加了 256 KB 头上限，属于放宽而非根治 —— 治本是 95 号让 cookie 名不再随端口膨胀。
- 宿主版本比 0.2.2-rc.1 更新时，被锚定的代码可能又变，面板会报 `drifted`；按 `docs/RELEASE-v1.1.92.md` 的对照表逐条重锚即可。
