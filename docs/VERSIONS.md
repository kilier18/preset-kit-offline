# 版本与来源记录

| 快照日期 | 版本 | 上游 commit | 上游 tag | 来源 | 校验 |
|---|---|---|---|---|---|
| 2026-11-04 | 1.1.90 | `217d60d3d61881079ea95bbe2c174f338a02182b` | `v1.1.90` | `~/.dsh/profiles/desktop/node_modules/dsh-preset-kit`（本机已应用并验收 68/70、0 drifted） | `pkg` 98 个文件 / 4.3 MB；`dist/dsh-preset-kit-1.1.90.tgz` 2.0 MB |
| 2026-11-07 | 1.1.91（安装器） | 同 1.1.90 | - | 本仓库自建 | `dist/dsh-preset-kit-setup-1.1.91.exe` 2.07 MB，内嵌 1.1.90 载荷 + `tools/` 两份脚本 |
| 2026-11-10 | 1.1.92 | 无上游（本地主线） | - | `~/.dsh/profiles/desktop/node_modules/dsh-purge`（本机 DSH **0.2.2-rc.1** 验收 `68/70 applied · 0 pending · 0 drifted`） | `pkg` 97 个文件 / 4.18 MB；`dist/dsh-preset-kit-1.1.92.tgz` 2,023,466 B；`dist/dsh-preset-kit-setup-1.1.92.exe` 内嵌同一载荷 |

> 1.1.92 起载荷换成 `dsh-purge` 主线（包名 `dsh-purge`，面板不显示包名），`dshTargets: ["0.2.1-rc.2", "0.2.1-rc.5", "0.2.2-rc.1"]`。
> 与 1.1.90 载荷不是同一份源码：1.1.90 是上游 preset-kit 快照，1.1.92 补丁表按 0.2.2-rc.1 重锚，**不可叠加安装**。

## 上游发布信息

- 仓库：<https://github.com/YuJunZhiXue/dsh-preset-kit>
- `v1.1.90` published `2026-11-02T08:58:26Z`，`prerelease: false`
- `dshTargets: ["0.2.1-rc.2", "0.2.1-rc.5"]`（这个字段自 **v1.1.88** 起才有，v1.1.84–v1.1.87 没有）

## 1.1.90 关键变更（据 release 正文）

- #208 Android 切后台输入框整块消失：撤销按钮改用 `createPortal` 挂到 `body`，脱离 composer
- 1.1.89：#204 cwd 用真实字面量（`interpolate: false`）、#207 桌面静默退出可诊断（新增 #92）
- rc.5 适配：release 说明称 rc.5 实机 pattern 全绿、沙箱 42 个目标文件 apply/revert 字节级还原

## 不要用的版本

- **npm 上的 `dsh-preset-kit`**：latest 是 `1.2.1`，来自第三方 Android 适配分支（maintainer `panda11445`，对应 repo `ccch1mneyyy/dsh-Go`）。上游 README 明确写过 npm 上没有这个包名，`pnpm add dsh-preset-kit` 会装到别人的分支。
- `1.1.84`–`1.1.87`：没有 rc.5 目标声明，装到 rc.5 上会被判"未适配"。

- **1.1.90 / 1.1.91**：在宿主 **0.2.2-rc.1** 上会报 9 个 `drifted`（#14/#17/#40/#54/#60/#62/#67/#74/#82），补丁等于没打。0.2.2-rc.1 请用 1.1.92。

## 快照内容说明

- `pkg/` 是**运行中实际加载的那份**，不是从 GitHub 重新拉的，因此包含 `lib/` 里已内联的默认提示词（上游 npm 包通过 `files` 排除了 `lib/default-prompt-inject.md` 源文件，内联结果在 `lib/` 的 js 里）。
- 排除：`pkg/node_modules/`（只有 13 KB 的 `.bin` 垫片，pnpm 会重建）。
- 保留：`LICENSE`、`NOTICE`（二开署名要求）、三份 README、`docs/`、`presets/`、`scripts/`、`client.js`、`cordis.patch.yml`、`screenshots.json`。

## 更新到新版本时

```bash
# 1) 新版本先在本机装好并验收（面板 0 drifted）
# 2) 重新快照
SRC=~/.dsh/profiles/desktop/node_modules/dsh-preset-kit
tar -cf - --exclude=node_modules -C "$SRC" . | tar -xf - -C pkg
# 3) 重建 tgz（package/ 根）
mkdir -p /tmp/package && cp -a pkg/. /tmp/package/ && tar -czf dist/dsh-preset-kit-<ver>.tgz -C /tmp /tmp/package
# 4) 更新本文件与 install-offline.ps1 的默认 -Tar 文件名
```