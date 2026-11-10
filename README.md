# dsh-preset-kit 离线安装包（v1.1.93）

一台能正常起来的环境里跑通过的 **预设工具箱 1.1.93**（npm 包名 `dsh-purge`，目录名沿用历史名）完整离线包，外加一套**不依赖插件市场/插件安装器**的落地脚本。
换新电脑、或者 DSH 面板死活装不上时，照下面走即可。

**适配宿主：DeepSeek Harness 0.2.2-rc.1**（`dshTargets` = `0.2.1-rc.2` / `0.2.1-rc.5` / `0.2.2-rc.1`）。

> **1.1.93 起，全新电脑双击一个 exe 就能用。** 官方分发只有 `resources\app.asar`（203 MB 打包体），而补丁必须落在 `resources\app\` 解包目录。1.1.92 及以前只装插件不处理 asar，所以新机器上「面板在、补丁 0 条生效」。1.1.93 把 asar 解包内置进安装器：解包 → 改名 → 重启宿主，一条龙。

## 下载

| 文件 | 大小 | 用途 |
|---|---|---|
| [`dsh-preset-kit-setup-1.1.93.exe`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.93/dsh-preset-kit-setup-1.1.93.exe) | 2,062,848 B | 单文件安装器，双击即装（已内嵌离线包 + 自动处理 asar） |
| [`dsh-preset-kit-1.1.92.tgz`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.93/dsh-preset-kit-1.1.92.tgz) | 2,023,466 B | 离线包本体（载荷未变），配合 `install\install.cmd` 或手动 `pnpm add file:` |
| [`SHA256SUMS.txt`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.93/SHA256SUMS.txt) | — | 校验值 |

整树克隆：`git clone https://github.com/kilier18/preset-kit-offline.git`（含 `tools/`、`docs/`、`install/`）。

- 宿主版本：**DSH 0.2.2-rc.1**（本机实测 `68/70 applied · 0 pending · 0 drifted`）
- 许可：Apache-2.0 + `pkg/NOTICE`（二开署名要求）

## 1.1.93 改了什么

载荷仍是 1.1.92（97 文件 / 2,023,466 B），变的是**安装器**：把 asar 解包搬进了 exe。

- **内置 asar 解包**：安装器读 `resources\app.asar` 的 16 字节头（`jsonLen` 在 offset 12，数据区起点 = `8 + u32(4)`），用 `JavaScriptSerializer` 解析文件树，递归写盘；`unpacked` 为真的条目从 `app.asar.unpacked\` 复制。实测本机 22,102 文件 / 462 MB / 21.8 秒。
- **解包后改名切目录**：`app.asar` → `app.asar.dshpurge.bak`，桌面端下次启动直接读 `resources\app`。
- **先试后杀**：先直接改名（3 次重试）；被占用才结束 `DeepSeek Harness` 进程、等 2 秒、再改名（12 次重试）；然后自动拉起桌面端。新增 `--no-kill` 可禁止杀进程，`--kill` 仍默认开启。
- **两种机器都对**：
  - 全新机器：`resources\app` 不存在 → 解包 → 改名 → 重启（`asar: 已解包并切换到 resources\app`）。
  - 老机器：`resources\app` 已存在 → 跳过解包、只改名（`asar: asar 已改名，下次启动读解包目录`）。
  - 已经在解包目录跑：报 `已在解包目录，无需处理`。
  - `--no-asar`：完全不动 asar（补丁不会生效，仅装插件时用）。
- **状态更清楚**：Summary 的 `asar` 行改为四种明确结果，不再统一说「无需处理」。
- **`install\build-exe.cmd` 修路径**：原文件 `cd /d "%~dp0"` 会让 `dist\` 指到 `install\dist`，已改成 `cd /d "%~dp0.."`。

1.1.92 的九处重锚（#14/#17/#40/#54/#60/#62/#67/#74/#82 + #35 markers）内容不变，见 [`docs/RELEASE-v1.1.92.md`](docs/RELEASE-v1.1.92.md)。

## 这是什么 / 能做什么

跑在 DeepSeek Harness 里的**本地策略工具箱**：

- **提示词注入**：会话开始时把本包自带的分类条目注入系统提示词，随包升级，不散落在各处
- **代码级修正**：把一组补丁写到 `resources\app` 解包目录，让宿主按本地策略运行（`patches: 68/70 applied`）
- **状态面板**：侧栏看 applied / pending / drifted，逐条看锚点落在哪个文件
- **回滚**：一键还原全部 `.bak`，回到官方原版行为

它不改 DSH 官方安装包本体：所有改动都落在 `resources\app`（解包目录）与 `~/.dsh` 下，改前留 `.bak`，随时可回滚。

## 目录

```
pkg/                                        载荷源码快照（97 个文件，去 node_modules）
src/Program.cs                              exe 源码（C# 5，csc 编译，载荷用 /resource 内嵌）
dist/dsh-preset-kit-setup-1.1.93.exe        一键离线安装器（2,062,848 B，无依赖）
dist/dsh-preset-kit-1.1.92.tgz              npm 格式离线包（package/ 根），可直接 pnpm add file:
dist/SHA256SUMS.txt                         校验值
install/install.cmd                         一键：调 install-offline.ps1
install/install-offline.ps1                 找 node/pnpm → pnpm add file:<tgz> --ignore-scripts → 补接线
install/wire-profile.mjs                    幂等接线：dependencies / dsh.profile.bundles / cordis.patch.yml insert
install/build-exe.cmd                       重编译安装器（产物落 dist\）
install/windows/swap-to-app-dir.cmd         把桌面端从 app.asar 切到 resources\app（带失败回滚，日志 %TEMP%）
docs/INSTALL-TROUBLESHOOTING.md             面板装不上时的几个成因与对应解法（含逐条验证命令）
docs/RESTORE.md                             新电脑从零到能用的完整顺序
docs/VERSIONS.md                            版本与来源记录
docs/RELEASE-v1.1.93.md                     本版逐条变更
docs/RELEASE-v1.1.92.md                     上一版（九处补丁重锚）的逐条对照
```

## 一键 exe（推荐：单文件、无依赖）

`dist\dsh-preset-kit-setup-1.1.93.exe`（2,062,848 B）把离线包内嵌在自身里，双击即可，不需要 node/pnpm/网络。

```bat
dsh-preset-kit-setup-1.1.93.exe --dry-run      :: 只探测：打印 DSH 路径、DSH_HOME、目标档案、载荷大小
dsh-preset-kit-setup-1.1.93.exe                :: 装 desktop（默认），需要时自动解包 asar + 重启
dsh-preset-kit-setup-1.1.93.exe --profile all  :: desktop + web + work
dsh-preset-kit-setup-1.1.93.exe --root "D:\Programs\DeepSeek Harness"
dsh-preset-kit-setup-1.1.93.exe --no-kill      :: asar 被占用时报错退出，不结束 DSH 进程
dsh-preset-kit-setup-1.1.93.exe --no-asar      :: 完全不动 app.asar（不解包、不改名；补丁不生效）
dsh-preset-kit-setup-1.1.93.exe --no-cal       :: 只装包，不做会话预检校准
dsh-preset-kit-setup-1.1.93.exe --cal-revert   :: 用校准备份把会话预检还原成默认
```

它依次做八件事：

1. **定位 DSH**：`--root` → `%LOCALAPPDATA%\Programs\DeepSeek Harness` → 注册表 Uninstall 项的 `InstallLocation` → `%ProgramFiles%\DeepSeek Harness`；校验 `DeepSeek Harness.exe` + `resources\`。
2. **定位档案**：`DSH_HOME`（默认 `%USERPROFILE%\.dsh`）下的 `profiles\{desktop,web,work}`；`node_modules` 是符号链接的档案（如 work→desktop）会跟着共用。
3. **解包**：内嵌 tgz → `node_modules\dsh-purge`（97 个文件，与 `pkg/` 字节一致），读完 `package.json` 校验版本。
4. **固化依赖**：tgz 另存一份到 `<profile>\.dsh-purge\dist\`，`package.json` 里写成 `file:./.dsh-purge/dist/dsh-preset-kit-1.1.92.tgz` —— 以后 `pnpm install` 会从这个相对路径自愈，不再依赖 GitHub。
5. **接线**：`dependencies.dsh-purge`、`dsh.profile.bundles`、`cordis.patch.yml` 的 `- insert:` 块各补一处；改完用 `JavaScriptSerializer` 校验 JSON，失败不落盘；原文件留 `.inst-bak`。重复跑幂等（第二次全是 `[=]`）。
6. **asar 解包 + 切目录（1.1.93 新增核心）**：`resources\app` 不存在就从 `app.asar` 解包（流式写，64 KB 缓冲；`unpacked` 条目从 `app.asar.unpacked\` 复制；偏移越界跳过并告警）；已存在就跳过解包。随后 `app.asar` → `app.asar.dshpurge.bak`：先直接试 3 次，被锁才杀进程再试 12 次（`--no-kill` 可禁）。杀过进程就自动拉起桌面端。
7. **会话预检校准**：给 `lib/net-scope.js` 的 `installRegionGate` 加一行早退，使 `agent/pre-step` 与 `tools/pre-execute` 两个前置钩子**不注册**（预检默认关闭）；本包自带的提示词条目**原样保留**，不做二次改写。原件备份到 `<DSH_HOME>\dsh-preset-kit\precheck-backup\<档案>\`，`--cal-revert` 一键还原；维护脚本落到 `<DSH_HOME>\dsh-preset-kit\calibrate.cmd`（`--status` / `--apply` / `--revert`）。步骤幂等：已校准的档案再跑只报 `预检=关闭`。
8. **收尾**：打印 `asar` 实际动作与下一步；若杀过宿主则已自动重启。

装完：等 30–60 秒让桌面端起来 → 侧栏 → 状态 → 复核 `68/70 applied · 0 pending · 0 drifted`（跳过两项是设计内）。

## 脚本安装（想要可审计的每一步）

```bat
:: 1) 先把 DSH 装好并能起来（0.2.2-rc.1）
:: 2) 装插件 + 接线（需要本机有 node/pnpm）
install\install.cmd
:: 3) 若桌面端还在读 app.asar：切到 resources\app
install\windows\swap-to-app-dir.cmd
:: 4) 启动桌面端 → 侧栏 → 校准 → 应用
:: 5) 验证：面板应为 68/70 applied、0 pending、0 drifted，且没有 "app.asar 还在" 告警
```

`install.cmd` 走 `pnpm add file:<tgz> --ignore-scripts`，然后手工跑同一个 `postinstall`，避免面板的构建脚本策略把安装判成失败（成因见 `docs/INSTALL-TROUBLESHOOTING.md`）。

## 回滚

| 想回到 | 怎么做 |
|---|---|
| 官方原版加载方式 | 把 `resources\app.asar.dshpurge.bak` 改回 `app.asar`，重启桌面端（`resources\app` 留着不影响） |
| 未打补丁的文件 | 面板「回滚」（还原所有 `.bak`） |
| 完全卸掉插件 | profile `package.json` 去掉 `dsh-purge` 依赖与 bundle 项，`pnpm install`，再删 `~/.dsh/dsh-preset-kit/` |

## 装之前注意

- **全新的 DSH、没装过同类预设插件**：双击 exe，等它解包（约 20–60 秒）并重启宿主，完事。
- **以前装过旧版（1.1.90 / 1.1.91 / 1.1.92）**：先在旧面板里「回滚」，或按上表还原 `.bak`，再卸载旧插件，然后装本包 —— 不同版本的补丁标记不同名，直接叠加会看到 `drifted` 告警，且文件里会留两套注释。
- **宿主比 0.2.2-rc.1 更新**：面板可能出现「未适配」提示与成片 `drifted`，说明宿主又改了被锚定的代码；此时看面板逐条对新版源码重锚（`docs/RELEASE-v1.1.92.md` 里的对照表就是上一轮的做法）。
- **每次 DSH 升级会重装回 `app.asar`**，补丁全部失效 —— 重跑一次 `dsh-preset-kit-setup-1.1.93.exe` 即可（它会把 asar 再解包、再切走）。
- 若桌面端还在读 `app.asar`（面板顶部有「app.asar 还在」告警），补丁等于没打：重跑安装器，或 `install\windows\swap-to-app-dir.cmd`。

## 重编译 exe

只用到 Windows 自带的 .NET Framework 编译器（`csc` 只支持 C# 5，源码里没用新语法）：

```bat
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
%CSC% /nologo /target:exe /platform:anycpu /optimize+ /codepage:65001 ^
  /out:dist\dsh-preset-kit-setup-1.1.93.exe ^
  /resource:dist\dsh-preset-kit-1.1.92.tgz,presetkitctl.payload.tgz ^
  /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
  /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
  /r:System.Web.Extensions.dll src\Program.cs
```

或直接跑 `install\build-exe.cmd`（工作目录会切到仓库根，产物落 `dist\`）。

Windows 自带 `tar.exe` 重打离线包（**必须** `--format=gnutar`，否则长名头与 npm pack 不一致）：

```bat
mkdir pack && xcopy /E /I pkg pack\package
tar --format=gnutar -czf dist\dsh-preset-kit-1.1.92.tgz -C pack package
```

## 校验

```bat
certutil -hashfile dist\dsh-preset-kit-setup-1.1.93.exe SHA256
certutil -hashfile dist\dsh-preset-kit-1.1.92.tgz SHA256
```

与 `dist/SHA256SUMS.txt` 对照。

## 来源与许可

本仓库是本地策略工具箱的离线快照 + 安装脚本，改动仅限打包与落地方式；插件源码保持 Apache-2.0 + `pkg/NOTICE`。二开请保留署名与来源链接。
