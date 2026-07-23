<#
.SYNOPSIS
    透過 codeload.githubusercontent.com 下載 GitHub public repo 特定 branch 的完整壓縮檔。

.DESCRIPTION
    不使用 git clone、不使用 github.com 網址、不使用 GitHub API。
    從 codeload.githubusercontent.com 下載 zip 格式壓縮檔，並解壓縮到指定目錄。

.PARAMETER Repo
    GitHub 儲存庫，格式為 owner/repo，例如 octocat/Hello-World

.PARAMETER Branch
    分支名稱，例如 main

.PARAMETER OutputDir
    (選填) 輸出目錄，預設為當前目錄

.EXAMPLE
    .\download-repo-codeload.ps1 -Repo "octocat/Hello-World" -Branch "main"

.EXAMPLE
    .\download-repo-codeload.ps1 -Repo "octocat/Hello-World" -Branch "main" -OutputDir ".\my-output"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "GitHub 儲存庫 (owner/repo)")]
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string]$Repo,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "分支名稱")]
    [ValidateNotNullOrEmpty()]
    [string]$Branch,

    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "輸出目錄")]
    [string]$OutputDir = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err   { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# 解析 owner/repo
# ---------------------------------------------------------------------------
$parts = $Repo -split '/'
$Owner = $parts[0]
$RepoName = $parts[1]

# ---------------------------------------------------------------------------
# 建立輸出目錄
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$OutputDir = (Resolve-Path -Path $OutputDir).Path

# ---------------------------------------------------------------------------
# 下載 zip (嘗試多種 URL 格式)
# ---------------------------------------------------------------------------
$urls = @(
    "https://codeload.githubusercontent.com/${Owner}/${RepoName}/zip/refs/heads/${Branch}",
    "https://codeload.githubusercontent.com/${Owner}/${RepoName}/zip/${Branch}",
    "https://codeload.githubusercontent.com/${Owner}/${RepoName}/legacy.zip/refs/heads/${Branch}"
)

$tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "github-download-$(Get-Random).zip"

Write-Info "輸出目錄: $OutputDir"

# 使用 TLS 1.2+
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
$ProgressPreference = 'SilentlyContinue'  # 加速 Invoke-WebRequest

$downloaded = $false
$lastError = $null

foreach ($url in $urls) {
    Write-Info "嘗試下載: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
        $downloaded = $true
        Write-Info "下載成功: $url"
        break
    }
    catch {
        $lastError = $_
        Write-Warn "失敗，嘗試下一個 URL..."
    }
}

if (-not $downloaded) {
    $statusCode = $null
    if ($lastError.Exception.Response) {
        $statusCode = [int]$lastError.Exception.Response.StatusCode
    }

    if ($statusCode -eq 404) {
        Write-Err "找不到儲存庫或分支: ${Owner}/${RepoName} @ ${Branch}"
    }
    elseif ($statusCode -eq 403) {
        Write-Err "存取被拒絕，可能是 private repo 或觸發速率限制"
    }
    else {
        Write-Err "所有 URL 格式都下載失敗: $($lastError.Exception.Message)"
    }

    exit 1
}

# 驗證檔案大小
$fileSize = (Get-Item -Path $tempFile).Length
if ($fileSize -lt 100) {
    Write-Err "下載的檔案過小 (${fileSize} bytes)，可能是空的或損壞的"
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# ---------------------------------------------------------------------------
# 解壓縮
# ---------------------------------------------------------------------------
Write-Info "解壓縮中..."

$tempExtractDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "github-extract-$(Get-Random)"

try {
    Expand-Archive -Path $tempFile -DestinationPath $tempExtractDir -Force

    # codeload 的 zip 會有一個頂層目錄 {repo_name}-{branch}/
    # 把頂層目錄裡的內容搬到輸出目錄
    $topLevelDir = Get-ChildItem -Path $tempExtractDir -Directory | Select-Object -First 1

    if ($null -eq $topLevelDir) {
        Write-Err "解壓縮後找不到頂層目錄"
        exit 1
    }

    # 複製所有內容到輸出目錄
    Get-ChildItem -Path $topLevelDir.FullName | ForEach-Object {
        $destPath = Join-Path -Path $OutputDir -ChildPath $_.Name
        if (Test-Path -Path $destPath) {
            Remove-Item -Path $destPath -Recurse -Force
        }
        Move-Item -Path $_.FullName -Destination $destPath -Force
    }
}
finally {
    # 清理暫存檔
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 完成
# ---------------------------------------------------------------------------
$fileCount = (Get-ChildItem -Path $OutputDir -Recurse -File).Count
$dirCount  = (Get-ChildItem -Path $OutputDir -Recurse -Directory).Count

Write-Info "完成！檔案已下載至: $OutputDir"
Write-Info "共 ${fileCount} 個檔案，${dirCount} 個目錄"
