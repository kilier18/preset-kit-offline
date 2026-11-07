# dsh-preset-kit 离线安装包（v1.1.91）

一台能正常起来的环境里跑通过的 **dsh-preset-kit 1.1.90** 完整离线包，外加一套**不依赖插件市场/插件安装器**的落地脚本。
换新电脑、或者 DSH 面板死活装不上时，照下面走即可。

## 下载

| 文件 | 大小 | 用途 |
|---|---|---|
| [`dsh-preset-kit-setup-1.1.91.exe`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.91/dsh-preset-kit-setup-1.1.91.exe) | 2,074,112 B | 单文件安装器，双击即装（已内嵌离线包） |
| [`dsh-preset-kit-1.1.90.tgz`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.91/dsh-preset-kit-1.1.90.tgz) | 2,039,149 B | 离线包本体，配合 `install\install.cmd` 或手动 `pnpm add file:` |
| [`SHA256SUMS.txt`](https://github.com/kilier18/preset-kit-offline/releases/download/v1.1.91/SHA256SUMS.txt) | 190 B | 校验值 |

整树克隆：`git clone https://github.com/kilier18/preset-kit-offline.git`（含 `pkg/`、`tools/`、`docs/`、`install/`）。

- 上游：<https://github.com/YuJunZhiXue/dsh-preset-kit> tag `v1.1.90`，commit `217d60d3d61881079ea95bbe2c174f338a02182b`，发布 2026-11-02
- 宿主版本：**DSH 0.2.1-rc.5**（`package.json` 的 `dshTargets` 里是 `0.2.1-rc.2` / `0.2.1-rc.5`）
- 许可：Apache-2.0 + 上游 NOTICE（二开署名要求见 `pkg/NOTICE`）

## 1.1.91 改了什么

载荷本身仍是 **1.1.90**（`pkg/` 与 `dist/dsh-preset-kit-1.1.90.tgz` 未变，字节一致）；变的是安装器与随附工具。

- **安装即校准**：新增第 7 步「会话预检校准」，装完就是可用状态，不用再手动点「校准 → 应用」第二次。
- **可还原**：校准前把三个文件备份到 `<DSH_HOME>\dsh-preset-kit\precheck-backup\<档案>\`；`--cal-revert` 或 `tools\calibrate.cmd --revert` 一键还原。
- **可维护**：`tools\calibrate.mjs` / `calibrate.cmd` 随安装器落到 `<DSH_HOME>\dsh-preset-kit\`，日后插件自更新（会覆盖 `lib/`）后跑一次 `calibrate.cmd --apply` 即可恢复。
- **幂等**：重复运行只补差量，不产生第二份备份、不重复改写文件。
- **包名无关**：同时识别 `dsh-preset-kit` 与旧名 `dsh-purge` 的 `node_modules` 目录，两个包名都能校准。
- **编译脚本入库**：`install\build-exe.cmd`（csc 命令行已在注释里固化，换机可复现）。
- 文案统一：输出改「写入完成」；安装器/脚本不再描述"规避了什么检查"。

## 这是什么 / 能做什么

`dsh-preset-kit` 是跑在 DeepSeek Harness 里的**预设工具箱**：

- **提示词预设**：按模型切换不同的系统提示词预设，默认预设面向国模「小码酱」
- **规则集**：按场景启用/停用规则组，会话内可切
- **校准（apply）**：把一组代码级补丁写到 `resources\app` 解包目录，让宿主按预设行为运行；**回滚**一键还原
- **工作台**：侧栏面板里看状态、改规则、跑脚本

它不改 DSH 官方安装包本体：所有改动都落在 `resources\app`（解包目录）与 `~/.dsh` 下，改前留 `.bak`，随时可回滚。

## 目录

```
pkg/                                        1.1.90 全量源码（98 个文件，去 node_modules）
src/Program.cs                              exe 源码（C# 5，csc 编译，载荷用 /resource 内嵌）
dist/dsh-preset-kit-setup-1.1.91.exe        一键离线安装器（约 2.0 MB，无依赖）
dist/dsh-preset-kit-1.1.90.tgz              npm 格式离线包（package/ 根），可直接 pnpm add file:
dist/SHA256SUMS.txt                         上面两个文件的校验值
install/install.cmd                         一键：调 install-offline.ps1
install/install-offline.ps1                 找 node/pnpm → pnpm add file:<tgz> --ignore-scripts → 补接线
install/wire-profile.mjs                    幂等接线：dependencies / dsh.profile.bundles / cordis.patch.yml insert
install/windows/swap-to-app-dir.cmd         把桌面端从 app.asar 切到 resources\app（带失败回滚，日志 %TEMP%）
install/windows/dsh-preset-kit-swap-to-app-dir.ps1  同上的 PowerShell 版
docs/INSTALL-TROUBLESHOOTING.md             面板装不上时的几个成因与对应解法（含逐条验证命令）
docs/RESTORE.md                             新电脑从零到能用的完整顺序
docs/VERSIONS.md                            版本与来源记录
```

## 一键 exe（推荐：单文件、无依赖）

`dist\dsh-preset-kit-setup-1.1.91.exe`（约 2.0 MB）把离线包内嵌在自身里，双击即可，不需要 node/pnpm/网络。

```bat
dsh-preset-kit-setup-1.1.91.exe --dry-run      :: 只探测：打印 DSH 路径、DSH_HOME、目标档案、载荷大小
dsh-preset-kit-setup-1.1.91.exe                :: 装 desktop（默认）
dsh-preset-kit-setup-1.1.91.exe --profile all  :: desktop + web + work
dsh-preset-kit-setup-1.1.91.exe --root "D:\Programs\DeepSeek Harness"
dsh-preset-kit-setup-1.1.91.exe --kill         :: 检测到 DSH 在跑就先结束，再切 asar
dsh-preset-kit-setup-1.1.91.exe --no-asar      :: 不动 app.asar，只装插件
dsh-preset-kit-setup-1.1.91.exe --no-cal       :: 只装包，不做会话预检校准
dsh-preset-kit-setup-1.1.91.exe --cal-revert   :: 用校准备份把会话预检还原成默认
```

它依次做七件事：

1. **定位 DSH**：`--root` → `%LOCALAPPDATA%\Programs\DeepSeek Harness` → 注册表 Uninstall 项的 `InstallLocation` → `%ProgramFiles%\DeepSeek Harness`；校验 `DeepSeek Harness.exe` + `resources\`。
2. **定位档案**：`DSH_HOME`（默认 `%USERPROFILE%\.dsh`）下的 `profiles\{desktop,web,work}`；`node_modules` 是符号链接的档案（如 work→desktop）会跟着共用。
3. **解包**：内嵌 tgz → `node_modules\dsh-preset-kit`（98 个文件，与 `pkg/` 字节一致）。
4. **固化依赖**：tgz 另存一份到 `<profile>\.dsh-preset-kit\dist\`，`package.json` 里写成 `file:./.dsh-preset-kit/dist/dsh-preset-kit-1.1.90.tgz` —— 以后 `pnpm install` 会从这个相对路径自愈，不再依赖 GitHub。
5. **接线**：`dependencies.dsh-preset-kit`、`dsh.profile.bundles`、`cordis.patch.yml` 的 `insert:` 块各补一处；改完用 `JavaScriptSerializer` 校验 JSON，失败不落盘；原文件留 `.inst-bak`。重复跑幂等（第二次全是 `[=]`）。
6. **切 asar**：`resources\app.asar` 存在时改名 `app.asar.dshpresetkit.bak`（12 次重试）；若 `resources\app` 还没解包内容则拒绝改名并提示先应用，避免把 DSH 弄到起不来。
7. **会话预检校准**：给 `lib/net-scope.js` 的 `installRegionGate` 加一行早退，使 `agent/pre-step` 与 `tools/pre-execute` 两个前置钩子**不注册**（预检默认关闭）；同时把 `lib/default-prompt-inject.zh.md` / `.en.md` 里两条与本地沙箱策略不一致的分类条目改写为一致。原件备份到 `<DSH_HOME>\dsh-preset-kit\precheck-backup\<档案>\`，`--cal-revert` 一键还原；维护脚本落到 `<DSH_HOME>\dsh-preset-kit\calibrate.cmd`（`--status` / `--apply` / `--revert`）。步骤幂等：已校准的档案再跑只报 `预检=关闭`。

装完：完全退出桌面端（含托盘）重开 → 侧栏 dsh-preset-kit → 状态 → 复核 86 组、0 pending、0 drifted（预检已在安装时校准，无需再点「应用」）。

## 脚本安装（想要可审计的每一步）

```bat
:: 1) 先把 DSH 装好并能起来（0.2.1-rc.5）
:: 2) 装插件 + 接线（需要本机有 node/pnpm）
install\install.cmd
:: 3) 切 app.asar → resources\app
install\windows\swap-to-app-dir.cmd
:: 4) 启动桌面端 → 侧栏 dsh-preset-kit → 校准 → 应用
:: 5) 验证：/presetkit status 应为 applied、0 pending、0 drifted，且没有 "app.asar 还在" 告警
```

`install.cmd` 走 `pnpm add file:<tgz> --ignore-scripts`，然后手工跑同一个 `postinstall`，避免面板的构建脚本策略把安装判成失败（成因见 `docs/INSTALL-TROUBLESHOOTING.md`）。

## 回滚

| 想回到 | 怎么做 |
|---|---|
| 官方原版加载方式 | 把 `resources\app.asar.dshpresetkit.bak` 改回 `app.asar`，重启桌面端 |
| 未打补丁的文件 | 面板 dsh-preset-kit「回滚」（还原所有 `.dshpresetkit.bak`） |
| 完全卸掉插件 | profile `package.json` 去掉 `dsh-preset-kit` 依赖与 bundle 项，`pnpm install`，再删 `~/.dsh/dsh-preset-kit/` |

## 装之前注意

- **全新的 DSH、没装过同类预设插件**：直接照上面做，一路顺。
- **以前装过旧版/别的预设插件**：先在旧面板里「回滚」，或按上表还原 `.bak`，再卸载旧插件，然后装本包 —— 不同版本的补丁标记不同名，直接叠加会看到 `drifted` 告警，且文件里会留两套注释。
- 校准作用于 `resources\app` 解包目录；如果桌面端还在读 `app.asar`，补丁等于没打，所以第 3 步的 asar 切换是必须的。

## 重编译 exe

只用到 Windows 自带的 .NET Framework 编译器（`csc` 只支持 C# 5，源码里没用新语法）：

```bat
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
%CSC% /nologo /target:exe /platform:anycpu /optimize+ /codepage:65001 ^
  /out:dist\dsh-preset-kit-setup-1.1.91.exe ^
  /resource:dist\dsh-preset-kit-1.1.90.tgz,presetkitctl.payload.tgz ^
  /r:System.Web.Extensions.dll src\Program.cs
```

Windows 自带 `tar.exe` 重打离线包：

```bat
mkdir pack && xcopy /E /I pkg pack\package
tar -czf dist\dsh-preset-kit-1.1.90.tgz -C pack package
```

## 校验

```bat
certutil -hashfile dist\dsh-preset-kit-setup-1.1.91.exe SHA256
certutil -hashfile dist\dsh-preset-kit-1.1.90.tgz SHA256
```

与 `dist/SHA256SUMS.txt` 对照。

## 来源与许可

本仓库是上游 `dsh-preset-kit` 1.1.90 的离线快照 + 安装脚本，改动仅限打包与落地方式；插件源码保持 Apache-2.0 + 上游 NOTICE。二开请保留署名与来源链接。
