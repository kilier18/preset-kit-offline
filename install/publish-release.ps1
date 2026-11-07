param(
    [string]$Token = $env:GITHUB_TOKEN,
    [string]$Repo  = "kilier18/preset-kit-offline",
    [string]$Tag   = "v1.1.90",
    [string]$Name  = "v1.1.90 · dsh-preset-kit 离线安装包（Windows 一键安装器）",
    [string]$Notes = "docs/RELEASE-v1.1.90.md"
)
$ErrorActionPreference = "Stop"
if (-not $Token) { Write-Host "[!] 需要 GitHub token（repo 权限）：`$env:GITHUB_TOKEN 或 -Token"; exit 2 }

$api = "https://api.github.com/repos/$Repo"
$h = @{ Authorization = "Bearer $Token"; "User-Agent" = "dsh-preset-kit-release"; Accept = "application/vnd.github+json" }

function Api($method, $url, $body) {
    if ($null -ne $body) {
        return Invoke-RestMethod -Method $method -Uri $url -Headers $h -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
    }
    return Invoke-RestMethod -Method $method -Uri $url -Headers $h
}

# 1) 找现有 release
$rel = $null
try { $rel = Api "GET" "$api/releases/tags/$Tag" $null } catch { $rel = $null }

$body = @{ tag_name = $Tag; name = $Name; body = (Get-Content $Notes -Raw -Encoding UTF8); draft = $false; prerelease = $false } | ConvertTo-Json -Depth 5

if ($rel) {
    Write-Host "[=] 更新 release $($rel.id)"
    $rel = Api "PATCH" "$api/releases/$($rel.id)" $body
} else {
    Write-Host "[+] 新建 release for $Tag"
    $rel = Api "POST" "$api/releases" $body
}

# 2) 上传/覆盖附件
$assets = @(
    @{ path = "dist/dsh-preset-kit-setup-1.1.90.exe"; name = "dsh-preset-kit-setup-1.1.90.exe" },
    @{ path = "dist/dsh-preset-kit-1.1.90.tgz";      name = "dsh-preset-kit-1.1.90.tgz" }
)
foreach ($a in $assets) {
    if (-not (Test-Path $a.path)) { Write-Host "[!] 缺文件 $($a.path)"; continue }
    $list = Api "GET" "$api/releases/$($rel.id)/assets" $null
    $hit = $list | Where-Object { $_.name -eq $a.name }
    if ($hit) {
        Write-Host "[=] 删除旧附件 $($a.name)"
        Api "DELETE" "$api/releases/assets/$($hit.id)" $null | Out-Null
    }
    $uploadUrl = "https://uploads.github.com/repos/$Repo/releases/$($rel.id)/assets?name=$($a.name)"
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path $a.path))
    Invoke-RestMethod -Method POST -Uri $uploadUrl -Headers $h -Body $bytes -ContentType "application/octet-stream" | Out-Null
    Write-Host "[+] 上传 $($a.name)  ($($bytes.Length) B)"
}
Write-Host "[OK] $($rel.html_url)"
