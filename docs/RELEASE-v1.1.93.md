# RELEASE v1.1.93

**一句话**：安装器内置 `resources\app.asar` 解包与切目录，全新电脑双击一个 exe 就能跑到 `68/70 applied`，不需要先手动解包。

## 载荷

| 项 | 值 |
|---|---|
| npm 包名 | `dsh-purge` |
| 插件版本 | 1.1.92（本轮**未变**） |
| 离线包 | `dist/dsh-preset-kit-1.1.92.tgz`，2,023,466 B，97 文件 |
| 安装器 | `dist/dsh-preset-kit-setup-1.1.93.exe`，2,062,848 B |
| `dshTargets` | `0.2.1-rc.2` / `0.2.1-rc.5` / `0.2.2-rc.1` |
| 适配宿主 | DeepSeek Harness **0.2.2-rc.1** |

## 变更

### 1. 内置 asar 解包（核心）

1.1.92 及以前只往 profile 里装插件、写 `cordis.patch.yml`，补丁要落的目标目录是
`resources\app\dsh\node_modules\@deepseek-ai\`。但官方分发包里只有 `resources\app.asar`（203 MB）
和 `resources\app.asar.unpacked\`，**没有 `resources\app\`**。结果：全新电脑装完，插件在、侧栏面板在，
但 `applied` 是 0 —— 补丁全落在没人读的目录上。

1.1.93 把解包搬进安装器：

- 读 16 字节头：`header[0..4]` 固定 4；`jsonLen = u32(12)`；数据区起点 `dataBase = 8 + u32(4)`。
- `offset 16` 起是 JSON 文件树，用 `JavaScriptSerializer`（`MaxJsonLength = int.MaxValue`）解析。
- `WalkAsarNode` 递归：有 `files` 键就是目录，建目录再递归；条目 `unpacked == true` 时从
  `<asar>.unpacked\<rel>` 复制（这些是原生模块，不在打包体里）；否则 `fs.Position = dataBase + offset`
  流式写出，64 KB 缓冲。
- 偏移越界、目标路径逃逸的条目跳过并打 `[x]`，不中断整包。
- 本机实测：**22,102 文件 / 462,661,959 B / 21.8 秒**，其中 1,583 个从 `app.asar.unpacked` 复制。

### 2. 解包后自动切目录

`app.asar` → `app.asar.dshpurge.bak`，桌面端下次启动直接读 `resources\app`。

改名策略改成「先试后杀」：

1. `TryMoveAsar(asar, target, 3)`：直接改，成功就**不碰任何进程**；
2. 失败且 `doKill`（默认 true）：结束所有 `Process.GetProcessesByName("DeepSeek Harness")`，
   `Sleep(2000)`，再 `TryMoveAsar(..., 12)`；
3. 成功后 `relaunchWanted = true`，在 `Main` 末尾 `Process.Start(<root>\DeepSeek Harness.exe)` 拉起宿主，
   并提示「等 30–60 秒让它完成补丁自应用」。

新增 `--no-kill`：被占用时只报错退出，不动用户进程。

### 3. 四种 asar 状态，各自说清

`HandleAsar` 分支与 Summary 文案一一对应：

| 场景 | 日志 | Summary `asar` 行 |
|---|---|---|
| `app.asar` 不存在（已在解包目录跑） | `[=] app.asar 已不在（桌面端已跑在解包目录），无需处理` | `已在解包目录，无需处理` |
| `--no-asar` | `[i] --no-asar：不动 app.asar（不解包、不改名）→ 补丁不会生效` | `跳过（--no-asar）` |
| 全新机器（`resources\app` 不存在） | `[*] resources\app 不存在 → 首次解包 app.asar（约 20-60 秒，目标 450-500 MB）` → `[+] asar 解包：目录 N 个，文件 M 个（其中从 .unpacked 复制 K 个）` → `[+] app.asar -> app.asar.dshpurge.bak` | `已解包并切换到 resources\app` |
| 老机器（`resources\app` 已存在） | `[=] resources\app 已存在，跳过解包` → `[+] app.asar -> app.asar.dshpurge.bak` | `asar 已改名，下次启动读解包目录` |

杀过进程的两种会在文案后追加「（宿主已重启）」。

### 4. `install\build-exe.cmd` 修路径 bug

原文件 `cd /d "%~dp0"` 停在 `install\`，于是 `/out:dist\...` 与 `/resource:dist\...`
都指向 `install\dist\`（不存在的目录），编译直接失败或产物落错地方。
1.1.93 改为 `cd /d "%~dp0.."`，输出名同步为 `dsh-preset-kit-setup-1.1.93.exe`。

### 5. `const string ExeVersion = "1.1.93"`

banner、`--help`、Summary 前缀都跟着变；`PkgVersion` 仍是 `1.1.92`（载荷没动）。

## 验证记录（本机实测）

### 夹具 A — 全新电脑（只有 `app.asar`）

```
[+] 离线包落地: ...\.dsh-purge\dist\dsh-preset-kit-1.1.92.tgz
[+] 解包 97 个文件 -> ...\node_modules\dsh-purge
[+] node_modules/dsh-purge 版本: 1.1.92
[+] dependencies 插入 dsh-purge
[+] bundles 追加 dsh-purge
[+] package.json 已更新（备份 package.json.inst-bak）
[+] cordis.patch.yml: 追加 insert 段（顶层数组元素）
[*] resources\app 不存在 → 首次解包 app.asar（约 20-60 秒，目标 450-500 MB）
[i] asar 头: jsonLen=227 B, 数据区起点=243
[+] asar 解包：目录 1 个，文件 5 个（其中从 .unpacked 复制 1 个）
[+] 解包完成，resources\app 已就绪
[+] app.asar -> app.asar.dshpurge.bak（320 B）
[OK] 写入完成
asar     : 已解包并切换到 resources\app
```

解出的内容逐项对过：`a.txt` = `hello`、`sub\b.js` 存在、`native.node` = `NATIVEBIN`（来自 `.unpacked`）、
`empty.bin` = 0 B。

### 夹具 B — 幂等重跑

```
[=] app.asar 已不在（桌面端已跑在解包目录），无需处理
[OK] 写入完成
asar     : 已在解包目录，无需处理
```

### 夹具 C — 老机器（`resources\app` 已存在、`app.asar` 仍在）

```
[=] resources\app 已存在，跳过解包
[+] app.asar -> app.asar.dshpurge.bak（320 B）
[OK] 写入完成
asar     : asar 已改名，下次启动读解包目录
```

跑完 `resources\app\lib\main.js` 与 `package.json` 原样保留，没有被解包内容覆盖。

### 夹具 D — `--dry-run`

只打印 `would unpack app.asar (N B) -> resources\app` 与 `would rename`，一个字节都不写。

### 生产环境（本机）

- `resources\app` 22,102 文件，`app.asar.dshpurge.bak` 203.3 MB，桌面端从解包目录运行。
- 侧栏 → 状态：`patches: 68/70 applied, 0 pending, 0 drifted`，宿主 `0.2.2-rc.1`，无「未适配」提示。

### 编译

```
csc /nologo /target:exe /codepage:65001 /optimize+ ^
  /out:dist\dsh-preset-kit-setup-1.1.93.exe ^
  /resource:dist\dsh-preset-kit-1.1.92.tgz,presetkitctl.payload.tgz ^
  /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
  /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
  /r:System.Web.Extensions.dll src\Program.cs
```

`rc=0`，唯一警告 `CS0414`（`assumeYes` 赋值未使用，无害）。

## 升级 / 回滚

升级（已装 1.1.90–1.1.92）：

```bat
:: 1) 旧面板先点「回滚」，把补丁撤干净
:: 2) 卸载旧插件（profile package.json 去掉依赖与 bundle，pnpm install）
:: 3) 装新包
dsh-preset-kit-setup-1.1.93.exe --profile desktop
```

回滚到官方加载方式：

```bat
ren "C:\Users\<你>\AppData\Local\Programs\DeepSeek Harness\resources\app.asar.dshpurge.bak" app.asar
:: 重启桌面端；resources\app 留着不影响
```

回滚补丁：面板「回滚」按钮，或逐个还原被改文件的 `.bak`。

`--cal-revert`：把会话预检恢复成默认（还原 `net-scope.js`）。

## 已知限制

1. **首次解包要 20–60 秒**，期间窗口没进度条；超时会看到长时间无输出，属正常。
2. **必须能写 `resources\`**：装在 `%LOCALAPPDATA%`（用户目录）时无需管理员；装在 `%ProgramFiles%` 时需要以管理员身份运行。
3. **DSH 每次升级会重装回 `app.asar`**，补丁全部失效 —— 重跑本 exe 即可。
4. **杀进程会丢未保存的会话草稿**；想避免就加 `--no-kill`，自己先退出桌面端。
5. **`pkg/` 与载荷的一致性**：`pkg/` 是 1.1.92 载荷的快照；本版没改载荷，所以 `pkg/` 不用动。
6. **`app.asar.unpacked` 里的原生模块**只按文件名复制，不校验哈希。
7. **不支持 macOS / Linux**：`csc` 产物是 PE32 .NET，路径全是 Windows 反斜杠。
