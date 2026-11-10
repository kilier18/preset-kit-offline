param(
    [string]$Token = $env:GITHUB_TOKEN,
    [string]$Repo  = "kilier18/preset-kit-offline",
    [string]$Tag   = "v1.1.93",
    [string]$Name  = "v1.1.93 · dsh-preset-kit 离线安装包（新电脑一键装，自动解包 asar）",
    [string]$Notes = "docs/RELEASE-v1.1.93.md"
)
$ErrorActionPreference = "Stop"

# GitHub API 只收 TLS 1.2+；PowerShell 5.1 默认还是 TLS 1.0，不设这行会全篇 WebException
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.ServicePointManager]::SecurityProtocol
} catch { }
try { [Net.ServicePointManager]::Expect100Continue = $false } catch { }

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
    @{ path = "dist/dsh-preset-kit-setup-1.1.93.exe"; name = "dsh-preset-kit-setup-1.1.93.exe" },
    @{ path = "dist/dsh-preset-kit-1.1.92.tgz";       name = "dsh-preset-kit-1.1.92.tgz" },
    @{ path = "dist/SHA256SUMS.txt";                 name = "SHA256SUMS.txt" }
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
