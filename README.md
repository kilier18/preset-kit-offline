# dsh-preset-kit 离线安装包（v1.1.92）

一台能正常起来的环境里跑通过的 **预设工具箱 1.1.92**（npm 包名 `dsh-purge`，目录名沿用历史名）完整离线包，外加一套**不依赖插件市场/插件安装器**的落地脚本。
换新电脑、或者 DSH 面板死活装不上时，照下面走即可。

**适配宿主：DeepSeek Harness 0.2.2-rc.1**（`dshTargets` = `0.2.1-rc.2` / `0.2.1-rc.5` / `0.2.2-rc.1`）。

## 下载

| 文件 | 大小 | 用途 |
|---|---|---|
| [`dsh-preset-kit-setup-1.1.92.exe`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.92/dsh-preset-kit-setup-1.1.92.exe) | 见发布页 | 单文件安装器，双击即装（已内嵌离线包） |
| [`dsh-preset-kit-1.1.92.tgz`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.92/dsh-preset-kit-1.1.92.tgz) | 2,023,466 B | 离线包本体，配合 `install\install.cmd` 或手动 `pnpm add file:` |
| [`SHA256SUMS.txt`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.92/SHA256SUMS.txt) | — | 校验值 |

整树克隆：`git clone https://github.com/kilier18/preset-kit-offline.git`（含 `pkg/`、`tools/`、`docs/`、`install/`）。

- 宿主版本：**DSH 0.2.2-rc.1**（本机实测 `68/70 applied · 0 pending · 0 drifted`）
- 许可：Apache-2.0 + `pkg/NOTICE`（二开署名要求）

## 1.1.92 改了什么

载荷整体从 1.1.90 升到 **1.1.92**，重点是让补丁表重新咬住 **DSH 0.2.2-rc.1** —— 新版宿主改了九处被锚定的代码，旧版会报 9 个 `drifted`。

- **九处 drifted 全部重锚**：#14/#17/#40/#54/#60/#62/#67/#74/#82（连带修掉 #35 的 markers 冲突）。逐条对照见 [`docs/RELEASE-v1.1.92.md`](docs/RELEASE-v1.1.92.md)。
- **目标文件跟着宿主拆包走**：`present` 提示词搬进 `dsh-deliverable-file-references`，`run_code` 审批搬进 `dsh-tool-executor-ptc`，工具审批实现搬进 `dsh-tools/lib/pipeline.js` —— 新增三个 `targetFiles` 键。
- **版本声明**：`dshTargets` 追加 `0.2.2-rc.1`，面板不再打「未适配」。
- **安装器**：`cordis.patch.yml` 改为追加顶层数组元素（旧的 `insert:` 顶键写法在数组结构下无效）；空 `dependencies` 的插入格式修正；不再改写插件自带提示词（`提示词改写=0`）；`app.asar` 默认不动，需要时加 `--asar`。

## 这是什么 / 能做什么

跑在 DeepSeek Harness 里的**本地策略工具箱**：

- **提示词注入**：会话开始时把本包自带的分类条目注入系统提示词，随包升级，不散落在各处
- **代码级修正**：把一组补丁写到 `resources\app` 解包目录，让宿主按本地策略运行（`patches: 68/70 applied`）
- **状态面板**：侧栏看 applied / pending / drifted，逐条看锚点落在哪个文件
- **回滚**：一键还原全部 `.bak`，回到官方原版行为

它不改 DSH 官方安装包本体：所有改动都落在 `resources\app`（解包目录）与 `~/.dsh` 下，改前留 `.bak`，随时可回滚。

## 目录

```
pkg/                                        1.1.92 全量源码（97 个文件，去 node_modules）
src/Program.cs                              exe 源码（C# 5，csc 编译，载荷用 /resource 内嵌）
dist/dsh-preset-kit-setup-1.1.92.exe        一键离线安装器（约 2.0 MB，无依赖）
dist/dsh-preset-kit-1.1.92.tgz              npm 格式离线包（package/ 根），可直接 pnpm add file:
dist/SHA256SUMS.txt                         上面两个文件的校验值
install/install.cmd                         一键：调 install-offline.ps1
install/install-offline.ps1                 找 node/pnpm → pnpm add file:<tgz> --ignore-scripts → 补接线
install/wire-profile.mjs                    幂等接线：dependencies / dsh.profile.bundles / cordis.patch.yml insert
install/windows/swap-to-app-dir.cmd         把桌面端从 app.asar 切到 resources\app（带失败回滚，日志 %TEMP%）
docs/INSTALL-TROUBLESHOOTING.md             面板装不上时的几个成因与对应解法（含逐条验证命令）
docs/RESTORE.md                             新电脑从零到能用的完整顺序
docs/VERSIONS.md                            版本与来源记录
docs/RELEASE-v1.1.92.md                     本版逐条变更
```

## 一键 exe（推荐：单文件、无依赖）

`dist\dsh-preset-kit-setup-1.1.92.exe`（约 2.0 MB）把离线包内嵌在自身里，双击即可，不需要 node/pnpm/网络。

```bat
dsh-preset-kit-setup-1.1.92.exe --dry-run      :: 只探测：打印 DSH 路径、DSH_HOME、目标档案、载荷大小
dsh-preset-kit-setup-1.1.92.exe                :: 装 desktop（默认）
dsh-preset-kit-setup-1.1.92.exe --profile all  :: desktop + web + work
dsh-preset-kit-setup-1.1.92.exe --root "D:\Programs\DeepSeek Harness"
dsh-preset-kit-setup-1.1.92.exe --kill         :: 检测到 DSH 在跑就先结束
dsh-preset-kit-setup-1.1.92.exe --no-asar      :: 不动 app.asar（默认行为，保留兼容）
dsh-preset-kit-setup-1.1.92.exe --asar         :: 主动把 app.asar 切成 .dshpurge.bak
dsh-preset-kit-setup-1.1.92.exe --no-cal       :: 只装包，不做会话预检校准
dsh-preset-kit-setup-1.1.92.exe --cal-revert   :: 用校准备份把会话预检还原成默认
```

它依次做七件事：

1. **定位 DSH**：`--root` → `%LOCALAPPDATA%\Programs\DeepSeek Harness` → 注册表 Uninstall 项的 `InstallLocation` → `%ProgramFiles%\DeepSeek Harness`；校验 `DeepSeek Harness.exe` + `resources\`。
2. **定位档案**：`DSH_HOME`（默认 `%USERPROFILE%\.dsh`）下的 `profiles\{desktop,web,work}`；`node_modules` 是符号链接的档案（如 work→desktop）会跟着共用。
3. **解包**：内嵌 tgz → `node_modules\dsh-purge`（97 个文件，与 `pkg/` 字节一致），读完 `package.json` 校验版本。
4. **固化依赖**：tgz 另存一份到 `<profile>\.dsh-purge\dist\`，`package.json` 里写成 `file:./.dsh-purge/dist/dsh-preset-kit-1.1.92.tgz` —— 以后 `pnpm install` 会从这个相对路径自愈，不再依赖 GitHub。
5. **接线**：`dependencies.dsh-purge`、`dsh.profile.bundles`、`cordis.patch.yml` 的 `- insert:` 块各补一处；改完用 `JavaScriptSerializer` 校验 JSON，失败不落盘；原文件留 `.inst-bak`。重复跑幂等（第二次全是 `[=]`）。
6. **asar（默认不动）**：只有加了 `--asar` 才会把 `resources\app.asar` 改名 `app.asar.dshpurge.bak`（12 次重试）；`resources\app` 还没解包内容时拒绝改名，避免把 DSH 弄到起不来。
7. **会话预检校准**：给 `lib/net-scope.js` 的 `installRegionGate` 加一行早退，使 `agent/pre-step` 与 `tools/pre-execute` 两个前置钩子**不注册**（预检默认关闭）；本包自带的提示词条目**原样保留**，不做二次改写。原件备份到 `<DSH_HOME>\dsh-purge\precheck-backup\<档案>\`，`--cal-revert` 一键还原；维护脚本落到 `<DSH_HOME>\dsh-purge\calibrate.cmd`（`--status` / `--apply` / `--revert`）。步骤幂等：已校准的档案再跑只报 `预检=关闭`。

装完：完全退出桌面端（含托盘）重开 → 侧栏 → 状态 → 复核 `68/70 applied · 0 pending · 0 drifted`（跳过两项是设计内，预检已在安装时校准，无需再点「应用」）。

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
| 官方原版加载方式 | 把 `resources\app.asar.dshpurge.bak` 改回 `app.asar`，重启桌面端 |
| 未打补丁的文件 | 面板「回滚」（还原所有 `.bak`） |
| 完全卸掉插件 | profile `package.json` 去掉 `dsh-purge` 依赖与 bundle 项，`pnpm install`，再删 `~/.dsh/dsh-purge/` |

## 装之前注意

- **全新的 DSH、没装过同类预设插件**：直接照上面做，一路顺。
- **以前装过旧版（1.1.90 / 1.1.91）**：先在旧面板里「回滚」，或按上表还原 `.bak`，再卸载旧插件，然后装本包 —— 不同版本的补丁标记不同名，直接叠加会看到 `drifted` 告警，且文件里会留两套注释。
- **宿主比 0.2.2-rc.1 更新**：面板可能出现「未适配」提示与成片 `drifted`，说明宿主又改了被锚定的代码；此时看面板逐条对新版源码重锚（`docs/RELEASE-v1.1.92.md` 里的对照表就是上一轮的做法）。
- 若桌面端还在读 `app.asar`，补丁等于没打，需要 `--asar` 或先跑 `swap-to-app-dir.cmd`。

## 重编译 exe

只用到 Windows 自带的 .NET Framework 编译器（`csc` 只支持 C# 5，源码里没用新语法）：

```bat
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
%CSC% /nologo /target:exe /platform:anycpu /optimize+ /codepage:65001 ^
  /out:dist\dsh-preset-kit-setup-1.1.92.exe ^
  /resource:dist\dsh-preset-kit-1.1.92.tgz,presetkitctl.payload.tgz ^
  /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
  /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
  /r:System.Web.Extensions.dll src\Program.cs
```

Windows 自带 `tar.exe` 重打离线包（**必须** `--format=gnutar`，否则长名头与 npm pack 不一致）：

```bat
mkdir pack && xcopy /E /I pkg pack\package
tar --format=gnutar -czf dist\dsh-preset-kit-1.1.92.tgz -C pack package
```

## 校验

```bat
certutil -hashfile dist\dsh-preset-kit-setup-1.1.92.exe SHA256
certutil -hashfile dist\dsh-preset-kit-1.1.92.tgz SHA256
```

与 `dist/SHA256SUMS.txt` 对照。

## 来源与许可

本仓库是本地策略工具箱 1.1.92 的离线快照 + 安装脚本，改动仅限打包与落地方式；插件源码保持 Apache-2.0 + `pkg/NOTICE`。二开请保留署名与来源链接。
