<#
.SYNOPSIS
    透過 raw.githubusercontent.com 根據檔案清單逐檔下載 GitHub public repo 的檔案。

.DESCRIPTION
    不使用 git clone、不使用 github.com 網址、不使用 GitHub API。
    根據使用者提供的檔案清單，從 raw.githubusercontent.com 逐一下載檔案，
    自動建立對應的目錄結構。

.PARAMETER Repo
    GitHub 儲存庫，格式為 owner/repo，例如 octocat/Hello-World

.PARAMETER Branch
    分支名稱，例如 main

.PARAMETER FileList
    檔案清單路徑，每行一個相對路徑

.PARAMETER OutputDir
    (選填) 輸出目錄，預設為當前目錄

.PARAMETER Parallel
    (選填) 平行下載數量，預設為 4

.EXAMPLE
    .\download-repo-raw.ps1 -Repo "octocat/Hello-World" -Branch "main" -FileList "files.txt"

.EXAMPLE
    .\download-repo-raw.ps1 -Repo "octocat/Hello-World" -Branch "main" -FileList "files.txt" -OutputDir ".\my-output" -Parallel 8
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "GitHub 儲存庫 (owner/repo)")]
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string]$Repo,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "分支名稱")]
    [ValidateNotNullOrEmpty()]
    [string]$Branch,

    [Parameter(Mandatory = $true, Position = 2, HelpMessage = "檔案清單路徑")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$FileList,

    [Parameter(Mandatory = $false, Position = 3, HelpMessage = "輸出目錄")]
    [string]$OutputDir = ".",

    [Parameter(Mandatory = $false, HelpMessage = "平行下載數量")]
    [ValidateRange(1, 32)]
    [int]$Parallel = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
function Write-Info { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err  { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# 解析 owner/repo
# ---------------------------------------------------------------------------
$parts = $Repo -split '/'
$Owner = $parts[0]
$RepoName = $parts[1]

# ---------------------------------------------------------------------------
# 讀取檔案清單
# ---------------------------------------------------------------------------
$fileLines = Get-Content -Path $FileList -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }

if ($fileLines.Count -eq 0) {
    Write-Err "檔案清單是空的: $FileList"
    exit 1
}

# ---------------------------------------------------------------------------
# 建立輸出目錄
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$OutputDir = (Resolve-Path -Path $OutputDir).Path

# ---------------------------------------------------------------------------
# 下載
# ---------------------------------------------------------------------------
Write-Info "儲存庫:   ${Owner}/${RepoName}"
Write-Info "分支:     ${Branch}"
Write-Info "檔案數量: $($fileLines.Count)"
Write-Info "平行數:   ${Parallel}"
Write-Info "輸出目錄: ${OutputDir}"
Write-Host ""

# 使用 TLS 1.2+
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

$successCount = 0
$failCount = 0
$ProgressPreference = 'SilentlyContinue'  # 加速 Invoke-WebRequest

# 定義下載腳本區塊
$downloadBlock = {
    param(
        [string]$FilePath,
        [string]$Owner,
        [string]$RepoName,
        [string]$Branch,
        [string]$OutputDir
    )

    $url = "https://raw.githubusercontent.com/${Owner}/${RepoName}/${Branch}/${FilePath}"
    $dest = Join-Path -Path $OutputDir -ChildPath $FilePath
    $destDir = Split-Path -Path $dest -Parent

    if (-not (Test-Path -Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        return @{ Path = $FilePath; Success = $true; Error = $null }
    }
    catch {
        if (Test-Path -Path $dest) {
            Remove-Item -Path $dest -Force -ErrorAction SilentlyContinue
        }
        return @{ Path = $FilePath; Success = $false; Error = $_.Exception.Message }
    }
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7+: 使用 ForEach-Object -Parallel
    $results = $fileLines | ForEach-Object -ThrottleLimit $Parallel -Parallel {
        $FilePath = $_
        $url = "https://raw.githubusercontent.com/$($using:Owner)/$($using:RepoName)/$($using:Branch)/${FilePath}"
        $dest = Join-Path -Path $using:OutputDir -ChildPath $FilePath
        $destDir = Split-Path -Path $dest -Parent

        if (-not (Test-Path -Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            [PSCustomObject]@{ Path = $FilePath; Success = $true; Error = $null }
        }
        catch {
            if (Test-Path -Path $dest) {
                Remove-Item -Path $dest -Force -ErrorAction SilentlyContinue
            }
            [PSCustomObject]@{ Path = $FilePath; Success = $false; Error = $_.Exception.Message }
        }
    }

    foreach ($r in $results) {
        if ($r.Success) {
            Write-Host "[OK]    $($r.Path)" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "[FAIL]  $($r.Path) - $($r.Error)" -ForegroundColor Red
            $failCount++
        }
    }
}
else {
    # PowerShell 5.x: 逐檔下載 (不支援 ForEach-Object -Parallel)
    foreach ($filePath in $fileLines) {
        $url = "https://raw.githubusercontent.com/${Owner}/${RepoName}/${Branch}/${filePath}"
        $dest = Join-Path -Path $OutputDir -ChildPath $filePath
        $destDir = Split-Path -Path $dest -Parent

        if (-not (Test-Path -Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            Write-Host "[OK]    $filePath" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "[FAIL]  $filePath - $($_.Exception.Message)" -ForegroundColor Red
            if (Test-Path -Path $dest) {
                Remove-Item -Path $dest -Force -ErrorAction SilentlyContinue
            }
            $failCount++
        }
    }
}

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "下載完成！"
Write-Info "成功: ${successCount}，失敗: ${failCount}，共 $($fileLines.Count) 個檔案"

if ($failCount -gt 0) {
    Write-Warn "有 ${failCount} 個檔案下載失敗，請檢查檔案路徑是否正確"
    exit 1
}
