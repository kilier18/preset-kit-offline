# dsh-preset-kit 离线安装包（v1.1.94）

一台能正常起来的环境里跑通过的 **预设工具箱 1.1.94**（npm 包名 `dsh-purge`，目录名沿用历史名）完整离线包，外加一套**不依赖插件市场/插件安装器**的落地脚本。
换新电脑、或者 DSH 面板死活装不上时，照下面走即可。

**适配宿主：DeepSeek Harness 0.2.2-rc.1**（`dshTargets` = `0.2.1-rc.2` / `0.2.1-rc.5` / `0.2.2-rc.1`）。

> [!TIP]
> ### 1.1.94 起：DSH 官方升级不用再手动重跑安装器
>
> 插件启动时发现桌面端又回到 `app.asar`，会在后台自己解包 → 重打补丁 → 预约改名（15 秒后跑，避开官方 Host 的 `Fiber._reload`，不杀进程、不重启）。你下次完全退出再打开，就是「解包目录 + 全量补丁」。

> [!WARNING]
> ### 全新电脑请只装 v1.1.94
>
> **v1.1.92 及以前的安装器不能直接装在全新电脑上** —— 它们只往 profile 里装插件、写 `cordis.patch.yml`，完全不碰 `resources\app.asar`。
> 而补丁要落的目标目录是 `resources\app\dsh\node_modules\@deepseek-ai\`，这个目录在官方分发包里**根本不存在**（官方只有 203 MB 的 `app.asar` 打包体）。
>
> 结果就是：装完插件在、侧栏面板在、**`applied` 是 0** —— 一条补丁都没生效，看起来像装了但没效果。
>
> 判断方法：打开侧栏「状态」，如果顶部有 `✗ app.asar 还在` 告警、或 `applied` 明显少于 `89`，就是这个情况。
>
> **解决**：装 [`v1.1.94`](https://github.com/kilier18/preset-kit-offline/releases/tag/v1.1.94) 的 exe。它把 asar 解包内置进去了：解包 → 改名 → 重启宿主，一条龙，双击即可。
>
> 已经在旧版上踩坑、`resources\app` 也已存在的机器，装 1.1.94 同样能修（它会跳过解包、只把 asar 改名）。

## 下载

只列**现在能用**的；历史版本见 [Releases](https://github.com/kilier18/preset-kit-offline/releases)。

| 文件 | 大小 | 用途 |
|---|---|---|
| [`dsh-preset-kit-setup-1.1.94.exe`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.94/dsh-preset-kit-setup-1.1.94.exe) | 2,063,872 B | **唯一推荐**：单文件安装器，双击即装（内嵌离线包 + 自动解包 asar + 启动自愈） |
| [`dsh-preset-kit-1.1.94.tgz`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.94/dsh-preset-kit-1.1.94.tgz) | 2,024,591 B | 插件本体（载荷，1.1.94 内嵌的就是它）；只在已有 `resources\app` 的机器上配合 `install\install.cmd` 手动用 |
| [`SHA256SUMS.txt`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.94/SHA256SUMS.txt) | — | 校验值 |

**不要装**：[`v1.1.92`](https://github.com/kilier18/preset-kit-offline/releases/tag/v1.1.92) / `v1.1.91` / `v1.1.90` 的 exe —— 全新电脑上补丁 0 条生效（1.1.90/1.1.91 另外还有 9 条 `drifted`）。`v1.1.93` 能装（自带解包），但没有启动自愈，也没有新增的三条补丁。

整树克隆：`git clone https://github.com/kilier18/preset-kit-offline.git`（含 `tools/`、`docs/`、`install/`）。

- 宿主版本：**DSH 0.2.2-rc.1**（本机实测 89 条补丁 · 0 drifted）
- 许可：Apache-2.0 + `pkg/NOTICE`（二开署名要求）

## 1.1.94 改了什么

载荷从 1.1.92（86 条补丁）升到 1.1.94（89 条），安装器同步跟版。

### 启动自愈（核心）

新增 `healSealedOnStart`（默认 `true`）。`lib/index.js` 的 `settleInstalledPatches` 里挂 `scheduleSealedHeal`：

- 只在 `surface === "desktop"` 且 `core.desktopAsarStillSealed()` 为真时排程，**15 秒后**跑（等官方 Host 的 `Fiber._reload` 结束，避免撞 `INACTIVE_EFFECT`）。
- 调 `reapply.reapplyInstalled({ upgrade: true })`：`openSealedDesktopHost` 按 `shouldExtractAsar({usable,identity,recorded,upgrade})` 判要不要重解包 → `extractAsarToSide` → `overlayAsarUnpacked` → `commitExtractedDir` → `revertAll` → `applyPatchesAllHosts` → `patchAllShims` → `markPatchesApplied` → `writeUnpackedAsarStamp`。
- 最后 `scheduleSealedDesktopRestart`：`renameAsarAside` 成功就直接改名；被占用就交给 `desktop.scheduleAsarRenameWhenIdle`（写 `<asar>.rename-pending` 锁 + `os.tmpdir()` 里的 detached PowerShell，等你退出后改名）。
- **不杀进程、不 `requestRestart`**，失败只写日志（`sealed heal: ok=false ...`），不阻塞启动；`sealedHealRunning` / `sealedHealDone` 双闸防重复。

### 三条新补丁（86 → 89）

| # | 名称 | 目标文件 | 作用 |
|---|---|---|---|
| 94 | `ASK_USER_WAIT_CAPPED` | `dsh-tool-ask-user/lib/index.js` | `args.timeout === -1` 收成 300 秒。模型传 `-1` 求「无限等待」时，会话会一直挂到手动打断 |
| 95 | `COOKIE_NAME_IGNORE_PORT` | `dsh-client-connection/lib/index.js` | 会话 cookie 名对 `authority` 去掉 `:端口`。桌面端每次换随机端口就多一份 cookie，累积到请求头超 8 KB 就被宿主回 431 |
| 96 | `HOST_MAX_HTTP_HEADER_SIZE` | `resources/app/lib/main.js` | 给 host 子进程加 `--max-http-header-size=262144`，兜住已积累的历史 cookie |

96 号的 pattern 是 `"--expose-internals",`（`main.js` 里唯一，host 子进程 `spawn(this.node, [...])` 的启动参数数组），替换后紧跟 `"--max-http-header-size=262144"`。

### 两个新 targetFiles 键

`tool-ask-user`、`client-connection`。0.2.2-rc.1 把 `ask_user` 的 timeout 收口与桌面 cookie 名拆到了独立插件，没有这两个键，94/95 必然 `nofile`。

### 安装器

- `PkgVersion` / `ExeVersion` → `1.1.94`，内嵌载荷换 `dsh-preset-kit-1.1.94.tgz`。
- 收尾提示改口径：`drifted = 0（1.1.94 共 89 条补丁，skipped 是设计内）`，不再写死 `68/70`。
- 其余沿用 1.1.93（内置解包、先试后杀、`--no-kill` / `--no-asar`、`build-exe.cmd` 的 `cd /d "%~dp0.."`）。

1.1.92 的九处重锚（#14/#17/#40/#54/#60/#62/#67/#74/#82 + #35 markers）见 [`docs/RELEASE-v1.1.92.md`](docs/RELEASE-v1.1.92.md)；1.1.93 的解包实现见 [`docs/RELEASE-v1.1.93.md`](docs/RELEASE-v1.1.93.md)。

## 这是什么 / 能做什么

跑在 DeepSeek Harness 里的**本地策略工具箱**：

- **提示词注入**：会话开始时把本包自带的分类条目注入系统提示词，随包升级，不散落在各处
- **代码级修正**：把 89 条补丁写到 `resources\app` 解包目录，让宿主按本地策略运行
- **启动自愈**：宿主升级退回 `app.asar` 时自动重解包、重打补丁
- **状态面板**：侧栏看 applied / pending / drifted，逐条看锚点落在哪个文件
- **回滚**：一键还原全部 `.bak`，回到官方原版行为

它不改 DSH 官方安装包本体：所有改动都落在 `resources\app`（解包目录）与 `~/.dsh` 下，改前留 `.bak`，随时可回滚。

## 目录

```
dist/dsh-preset-kit-1.1.94.tgz 展开后的 package/    载荷源码（97 个文件，去 node_modules）
src/Program.cs                              exe 源码（C# 5，csc 编译，载荷用 /resource 内嵌）
dist/dsh-preset-kit-setup-1.1.94.exe        一键离线安装器（2,063,872 B，无依赖）
dist/dsh-preset-kit-1.1.94.tgz              npm 格式离线包（package/ 根），可直接 pnpm add file:
dist/SHA256SUMS.txt                         校验值
install/install.cmd                         一键：调 install-offline.ps1
install/install-offline.ps1                 找 node/pnpm → pnpm add file:<tgz> --ignore-scripts → 补接线
install/wire-profile.mjs                    幂等接线：dependencies / dsh.profile.bundles / cordis.patch.yml insert
install/build-exe.cmd                       重编译安装器（产物落 dist\）
install/windows/swap-to-app-dir.cmd         把桌面端从 app.asar 切到 resources\app（带失败回滚，日志 %TEMP%）
docs/INSTALL-TROUBLESHOOTING.md             面板装不上时的几个成因与对应解法（含逐条验证命令）
docs/RESTORE.md                             新电脑从零到能用的完整顺序
docs/VERSIONS.md                            版本与来源记录
docs/RELEASE-v1.1.94.md                     本版逐条变更（启动自愈 + 三条补丁）
docs/RELEASE-v1.1.93.md                     安装器内置 asar 解包
docs/RELEASE-v1.1.92.md                     九处补丁重锚的逐条对照
```

## 一键 exe（推荐：单文件、无依赖）

`dist\dsh-preset-kit-setup-1.1.94.exe`（2,063,872 B）把离线包内嵌在自身里，双击即可，不需要 node/pnpm/网络。

```bat
dsh-preset-kit-setup-1.1.94.exe --dry-run      :: 只探测：打印 DSH 路径、DSH_HOME、目标档案、载荷大小
dsh-preset-kit-setup-1.1.94.exe                :: 装 desktop（默认），需要时自动解包 asar + 重启
dsh-preset-kit-setup-1.1.94.exe --profile all  :: desktop + web + work
dsh-preset-kit-setup-1.1.94.exe --root "D:\Programs\DeepSeek Harness"
dsh-preset-kit-setup-1.1.94.exe --no-kill      :: asar 被占用时报错退出，不结束 DSH 进程
dsh-preset-kit-setup-1.1.94.exe --no-asar      :: 完全不动 app.asar（不解包、不改名；补丁不生效）
dsh-preset-kit-setup-1.1.94.exe --no-cal       :: 只装包，不做会话预检校准
dsh-preset-kit-setup-1.1.94.exe --cal-revert   :: 用校准备份把会话预检还原成默认
```

它依次做八件事：

1. **定位 DSH**：`--root` → `%LOCALAPPDATA%\Programs\DeepSeek Harness` → 注册表 Uninstall 项的 `InstallLocation` → `%ProgramFiles%\DeepSeek Harness`；校验 `DeepSeek Harness.exe` + `resources\`。
2. **定位档案**：`DSH_HOME`（默认 `%USERPROFILE%\.dsh`）下的 `profiles\{desktop,web,work}`；`node_modules` 是符号链接的档案（如 work→desktop）会跟着共用。
3. **解包**：内嵌 tgz → `node_modules\dsh-purge`（97 个文件，与内嵌 tgz 字节一致），读完 `package.json` 校验版本。
4. **固化依赖**：tgz 另存一份到 `<profile>\.dsh-purge\dist\`，`package.json` 里写成 `file:./.dsh-purge/dist/dsh-preset-kit-1.1.94.tgz` —— 以后 `pnpm install` 会从这个相对路径自愈，不再依赖 GitHub。
5. **接线**：`dependencies.dsh-purge`、`dsh.profile.bundles`、`cordis.patch.yml` 的 `- insert:` 块各补一处；改完用 `JavaScriptSerializer` 校验 JSON，失败不落盘；原文件留 `.inst-bak`。重复跑幂等（第二次全是 `[=]`）。
6. **asar 解包 + 切目录**：`resources\app` 不存在就从 `app.asar` 解包（16 字节头 + `jsonLen` 在 offset 12、数据区起点 `8 + u32(4)`；`unpacked` 条目从 `app.asar.unpacked\` 复制；64 KB 缓冲流式写；偏移越界跳过并告警）；已存在就跳过解包。随后 `app.asar` → `app.asar.dshpurge.bak`：先直接试 3 次，被锁才杀进程再试 12 次（`--no-kill` 可禁）。杀过进程就自动拉起桌面端。
7. **会话预检校准**：给 `lib/net-scope.js` 的 `installRegionGate` 加一行早退，使 `agent/pre-step` 与 `tools/pre-execute` 两个前置钩子**不注册**（预检默认关闭）；本包自带的提示词条目**原样保留**，不做二次改写。原件备份到 `<DSH_HOME>\dsh-preset-kit\precheck-backup\<档案>\`，`--cal-revert` 一键还原；维护脚本落到 `<DSH_HOME>\dsh-preset-kit\calibrate.cmd`（`--status` / `--apply` / `--revert`）。步骤幂等。
8. **收尾**：打印 `asar` 实际动作与下一步；若杀过宿主则已自动重启。

装完：等 30–60 秒让桌面端起来 → 侧栏 → 状态 → 复核 `drifted = 0`（`skipped` 两项是设计内）。

## 脚本安装（想要可审计的每一步）

```bat
:: 1) 先把 DSH 装好并能起来（0.2.2-rc.1）
:: 2) 装插件 + 接线（需要本机有 node/pnpm）
install\install.cmd
:: 3) 若桌面端还在读 app.asar：切到 resources\app
install\windows\swap-to-app-dir.cmd
:: 4) 启动桌面端 → 侧栏 → 校准 → 应用
:: 5) 验证：面板应为 drifted = 0，且没有 "app.asar 还在" 告警
```

`install.cmd` 走 `pnpm add file:<tgz> --ignore-scripts`，然后手工跑同一个 `postinstall`，避免面板的构建脚本策略把安装判成失败（成因见 `docs/INSTALL-TROUBLESHOOTING.md`）。

## 回滚

| 想回到 | 怎么做 |
|---|---|
| 官方原版加载方式 | 把 `resources\app.asar.dshpurge.bak` 改回 `app.asar`，重启桌面端（`resources\app` 留着不影响） |
| 未打补丁的文件 | 面板「回滚」（还原所有 `.bak`） |
| 完全卸掉插件 | profile `package.json` 去掉 `dsh-purge` 依赖与 bundle 项，`pnpm install`，再删 `~/.dsh/dsh-preset-kit/` |

## 装之前注意

- **全新的 DSH、没装过同类预设插件**：双击 `dsh-preset-kit-setup-1.1.94.exe`，等它解包（约 20–60 秒）并重启宿主，完事。**别用 1.1.92 及以前的 exe**（见顶部警告）。
- **以前装过旧版（1.1.90 / 1.1.91 / 1.1.92）**：先在旧面板里「回滚」，或按上表还原 `.bak`，再卸载旧插件，然后装本包 —— 不同版本的补丁标记不同名，直接叠加会看到 `drifted` 告警，且文件里会留两套注释。
- **装过 1.1.92 且 `applied` 是 0**：不用回滚，直接装 1.1.94 —— 它检测到 `resources\app` 已存在就跳过解包，只把 `app.asar` 改名切走，然后重启宿主，补丁就生效了。
- **DSH 官方升级之后**：1.1.94 起的插件会自己解包 + 重打补丁（见顶部 TIP）。如果面板显示 `sealed heal: ok=false`，说明解包失败，看日志再手动跑一次安装器。
- **宿主比 0.2.2-rc.1 更新**：面板可能出现「未适配」提示与成片 `drifted`，说明宿主又改了被锚定的代码；此时看面板逐条对新版源码重锚（`docs/RELEASE-v1.1.92.md` 里的对照表就是上一轮的做法）。
- 若桌面端还在读 `app.asar`（面板顶部有「app.asar 还在」告警），补丁等于没打：重跑安装器，或 `install\windows\swap-to-app-dir.cmd`。

## 重编译 exe

只用到 Windows 自带的 .NET Framework 编译器（`csc` 只支持 C# 5，源码里没用新语法）：

```bat
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
%CSC% /nologo /target:exe /platform:anycpu /optimize+ /codepage:65001 ^
  /out:dist\dsh-preset-kit-setup-1.1.94.exe ^
  /resource:dist\dsh-preset-kit-1.1.94.tgz,presetkitctl.payload.tgz ^
  /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
  /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
  /r:System.Web.Extensions.dll src\Program.cs
```

或直接跑 `install\build-exe.cmd`（工作目录会切到仓库根，产物落 `dist\`）。

Windows 自带 `tar.exe` 重打离线包（**必须** `--format=gnutar`，否则长名头与 npm pack 不一致）：

```bat
mkdir pack && xcopy /E /I pkg pack\package
tar --format=gnutar -czf dist\dsh-preset-kit-1.1.94.tgz -C pack package
```

## 校验

```bat
certutil -hashfile dist\dsh-preset-kit-setup-1.1.94.exe SHA256
certutil -hashfile dist\dsh-preset-kit-1.1.94.tgz SHA256
```

与 `dist/SHA256SUMS.txt` 对照：

```
481b4d9c763ca122d67eea4f14a50ec214da800f7ba3b965063d0cf71fbe8a49 *dsh-preset-kit-setup-1.1.94.exe
809dd52adde4c2580fca4df5448bce727f268d25d54c54fdc2996ea26545028a *dsh-preset-kit-1.1.94.tgz
```

## 来源与许可

本仓库是本地策略工具箱的离线快照 + 安装脚本，改动仅限打包与落地方式；插件源码保持 Apache-2.0 + `pkg/NOTICE`。二开请保留署名与来源链接。
