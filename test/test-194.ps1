# test-194.ps1 — 1.1.94 安装器三场景验证（全新 / 老机器 / 幂等）
$ErrorActionPreference = 'Stop'
$node = 'C:\Users\pinn\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\node\bin\node.exe'
$setup = 'D:\DSH\workspace\default-workspace\pkg-build\repo\dist\dsh-preset-kit-setup-1.1.94.exe'
$mk = 'D:\DSH\workspace\default-workspace\pkg-build\repo\test\make-test-asar.mjs'
$base = 'D:\DSH\workspace\default-workspace\pkg-build\test194'

function New-Fixture([string]$name) {
  $root = Join-Path $base $name
  Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
  $dsh = Join-Path $root 'dsh-root'
  $fakeHome = Join-Path $root 'fake-home'
  New-Item -ItemType Directory -Force -Path (Join-Path $dsh 'resources') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $fakeHome 'profiles\desktop') | Out-Null
  New-Item -ItemType File -Force -Path (Join-Path $dsh 'DeepSeek Harness.exe') | Out-Null
  $pkgJson = @"
{
  "name": "dsh-profile-desktop",
  "private": true,
  "dependencies": {},
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base"
      ]
    }
  }
}
"@
  [System.IO.File]::WriteAllText((Join-Path $fakeHome 'profiles\desktop\package.json'), $pkgJson)
  [System.IO.File]::WriteAllText((Join-Path $fakeHome 'profiles\desktop\cordis.patch.yml'), "# test`n")
  & $node $mk (Join-Path $dsh 'resources\app.asar') | Out-Null
  return [pscustomobject]@{ Root = $root; Dsh = $dsh; FakeHome = $fakeHome }
}

function Run-Setup($fx, [string]$tag) {
  Write-Output ""
  Write-Output "########## $tag ##########"
  $env:DSH_HOME = $fx.FakeHome
  try {
    & $setup --root $fx.Dsh --profile desktop --yes 2>&1 | Select-Object -Last 24
  } finally {
    Remove-Item Env:\DSH_HOME -ErrorAction SilentlyContinue
  }
}

function Show-Tree($fx, [string]$tag) {
  Write-Output "--- $tag 结果 ---"
  $res = Join-Path $fx.Dsh 'resources'
  Get-ChildItem $res -Force | ForEach-Object { "  {0,-26} {1,10:N0}" -f $_.Name, $(if ($_.PSIsContainer) { 0 } else { $_.Length }) }
  $app = Join-Path $res 'app'
  if (Test-Path $app) {
    $files = Get-ChildItem $app -Recurse -File
    Write-Output ("  app 文件数: {0}" -f $files.Count)
    foreach ($n in @('package.json','a.txt','sub\b.js','native.node','empty.bin')) {
      $p = Join-Path $app $n
      if (Test-Path $p) { Write-Output ("    {0,-14} {1,8:N0} B  {2}" -f $n, (Get-Item $p).Length, $(if ((Get-Item $p).Length -lt 40) { (Get-Content $p -Raw) } else { '' })) }
    }
  }
  $pkg = Join-Path $fx.FakeHome 'profiles\desktop\package.json'
  Write-Output "  profile package.json:"
  Get-Content $pkg | ForEach-Object { "    $_" }
  $yml = Join-Path $fx.FakeHome 'profiles\desktop\cordis.patch.yml'
  Write-Output "  cordis.patch.yml:"
  Get-Content $yml | ForEach-Object { "    $_" }
  $plug = Join-Path $fx.FakeHome 'profiles\desktop\node_modules\dsh-purge'
  if (Test-Path $plug) {
    Write-Output ("  插件目录: {0} 文件" -f (Get-ChildItem $plug -Recurse -File).Count)
    $v = (Get-Content (Join-Path $plug 'package.json') -Raw | ConvertFrom-Json).version
    Write-Output "  插件版本: $v"
    Write-Output ("  core.js 含 #96: {0}" -f (Select-String -Path (Join-Path $plug 'lib\core.js') -Pattern 'HOST_MAX_HTTP_HEADER_SIZE' -Quiet))
    Write-Output ("  index.js 含 heal: {0}" -f (Select-String -Path (Join-Path $plug 'lib\index.js') -Pattern 'healSealedOnStart' -Quiet))
  } else { Write-Output '  插件目录: 缺失' }
}

Remove-Item $base -Recurse -Force -ErrorAction SilentlyContinue

# 场景 A：全新电脑
$a = New-Fixture 'A-fresh'
Write-Output '=== A 前置：只有 app.asar ==='
Get-ChildItem (Join-Path $a.Dsh 'resources') -Force | ForEach-Object { "  $($_.Name)" }
Run-Setup $a 'A 全新电脑'
Show-Tree $a 'A'

# 场景 B：老机器（resources\app 已存在 + asar 仍在）
$b = New-Fixture 'B-old'
$bapp = Join-Path $b.Dsh 'resources\app'
New-Item -ItemType Directory -Force -Path (Join-Path $bapp 'lib') | Out-Null
[System.IO.File]::WriteAllText((Join-Path $bapp 'package.json'), '{"name":"already-unpacked","version":"old"}')
[System.IO.File]::WriteAllText((Join-Path $bapp 'lib\main.js'), '// MARKER-OLD-APP')
Write-Output ''
Write-Output '=== B 前置 ==='
Get-ChildItem (Join-Path $b.Dsh 'resources') -Force | ForEach-Object { "  $($_.Name)" }
Run-Setup $b 'B 老机器（已有 app 目录）'
Show-Tree $b 'B'
Write-Output '  B app 内容保留检查：'
Write-Output ("    package.json = {0}" -f (Get-Content (Join-Path $bapp 'package.json') -Raw))
Write-Output ("    lib\main.js  = {0}" -f (Get-Content (Join-Path $bapp 'lib\main.js') -Raw))

# 场景 C：幂等重跑
Run-Setup $b 'C 幂等重跑'
Write-Output ''
Write-Output '=== 全部完成 ==='
