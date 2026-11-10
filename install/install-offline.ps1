#Requires -Version 5.1
<#
  install-offline.ps1 - install dsh-preset-kit into a DSH profile from a local tarball,
  for offline machines where the plugin installer / marketplace is unavailable.

  Usage (from the repo root):
    powershell -ExecutionPolicy Bypass -File install\install-offline.ps1
    powershell -ExecutionPolicy Bypass -File install\install-offline.ps1 -Profile work -Tar dist\dsh-preset-kit-1.1.92.tgz

  ASCII only: safe to run from cmd.exe or PowerShell without code page setup.
#>
[CmdletBinding()]
param(
  [string]$Profile = "desktop",
  [string]$Tar = "",
  [string]$Pnpm = "",
  [string]$Node = "",
  [string]$Spec = "",
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Tar) { $Tar = Join-Path $repo "dist\dsh-preset-kit-1.1.92.tgz" }
if (-not (Test-Path $Tar)) { throw "tarball not found: $Tar" }
$Tar = (Resolve-Path $Tar).Path
if (-not $Spec) { $Spec = "file:$Tar" }

$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE ".dsh" }
$profileDir = Join-Path $dshHome "profiles\$Profile"
if (-not (Test-Path (Join-Path $profileDir "package.json"))) { throw "profile not found: $profileDir" }

# --- locate the bundled node / pnpm (PATH usually has neither) ---
$runtimeRoot = Join-Path $env:LOCALAPPDATA "Programs\DeepSeek Harness\resources\runtime\primary-runtime\dependencies"
if (-not $Node) { $Node = Join-Path $runtimeRoot "node\bin\node.exe" }
if (-not (Test-Path $Node)) { $Node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source }
if (-not $Node) { throw "node.exe not found (looked in bundled runtime and PATH)" }
if (-not $Pnpm) { $Pnpm = Join-Path $runtimeRoot "pnpm\bin\pnpm.cjs" }
if (-not (Test-Path $Pnpm)) { throw "pnpm.cjs not found: $Pnpm" }

Write-Host "[i] node  = $Node"
Write-Host "[i] pnpm  = $Pnpm"
Write-Host "[i] tar   = $Tar"
Write-Host "[i] prof  = $profileDir"

if (-not $SkipInstall) {
  Push-Location $profileDir
  try {
    # --ignore-scripts: skip postinstall (that is what trips ERR_PNPM_IGNORED_BUILDS anyway)
    Write-Host "[*] pnpm add file:<tarball> --ignore-scripts"
    & $Node $Pnpm add "file:$Tar" --ignore-scripts
    if ($LASTEXITCODE -ne 0) { throw "pnpm add failed with exit $LASTEXITCODE" }
  } finally { Pop-Location }
}

# --- postinstall equivalent, run by hand (pure file ops, no scripts policy involved) ---
$ensure = Join-Path $profileDir "node_modules\dsh-purge\scripts\ensure-profile-bundle.mjs"
if (Test-Path $ensure) {
  Write-Host "[*] node scripts/ensure-profile-bundle.mjs"
  Push-Location $profileDir
  try { & $Node "node_modules\dsh-purge\scripts\ensure-profile-bundle.mjs" } finally { Pop-Location }
} else {
  Write-Warning "ensure-profile-bundle.mjs missing - package did not land in node_modules"
}

# --- wire bundles + cordis.patch.yml (idempotent) ---
Write-Host "[*] wiring profile"
& $Node (Join-Path $repo "install\wire-profile.mjs") --profile $Profile --spec $Spec

Write-Host ""
Write-Host "[done] checks:"
$installed = Join-Path $profileDir "node_modules\dsh-purge\package.json"
if (Test-Path $installed) {
  $v = (Get-Content $installed -Raw | ConvertFrom-Json).version
  Write-Host ("  plugin version in node_modules: {0}" -f $v)
} else { Write-Warning "  dsh-purge not present in node_modules" }
Write-Host "  next: fully quit DeepSeek Harness (tray too), start it, then in the dsh-preset-kit panel: clean -> apply"
Write-Host "  if resources\app.asar still exists, run dsh-preset-kit-swap-to-app-dir.cmd afterwards"