# GitHub Repo Downloader via githubusercontent.com

透過 `*.githubusercontent.com` 網域下載 GitHub public repo 的特定 branch 所有檔案。

**不使用** `git clone`、`github.com` 網址、GitHub API (`api.github.com`)。

## 兩種下載方式

| 方式 | 網域 | 說明 | 適用情境 |
|------|------|------|----------|
| **codeload** | `codeload.githubusercontent.com` | 下載整個 branch 的壓縮檔 (tar.gz/zip) | 需要完整 repo 所有檔案 |
| **raw** | `raw.githubusercontent.com` | 根據檔案清單逐檔下載 | 只需要部分特定檔案 |

## 方式一：codeload — 整包下載（推薦）

### Linux / macOS (Bash)

```bash
chmod +x download-repo-codeload.sh

# 下載到當前目錄
./download-repo-codeload.sh octocat/Hello-World main

# 下載到指定目錄
./download-repo-codeload.sh octocat/Hello-World main ./my-output
```

### Windows (PowerShell)

```powershell
# 下載到當前目錄
.\download-repo-codeload.ps1 -Repo "octocat/Hello-World" -Branch "main"

# 下載到指定目錄
.\download-repo-codeload.ps1 -Repo "octocat/Hello-World" -Branch "main" -OutputDir ".\my-output"
```

### 參數

| 參數 | 必填 | 說明 | 範例 |
|------|------|------|------|
| `owner/repo` | 是 | GitHub 儲存庫 | `octocat/Hello-World` |
| `branch` | 是 | 分支名稱 | `main` |
| `output_dir` | 否 | 輸出目錄 (預設：當前目錄) | `./my-output` |

### 運作原理

```
codeload.githubusercontent.com/{owner}/{repo}/tar.gz/refs/heads/{branch}  → Linux (tar.gz)
codeload.githubusercontent.com/{owner}/{repo}/zip/refs/heads/{branch}     → Windows (zip)
```

## 方式二：raw — 逐檔下載

需要先準備一份檔案清單 (`file-list.txt`)，每行一個相對路徑：

```text
# file-list.txt 範例
README.md
src/main.py
docs/guide.md
```

### Linux / macOS (Bash)

```bash
chmod +x download-repo-raw.sh

# 基本用法
./download-repo-raw.sh octocat/Hello-World main files.txt

# 指定輸出目錄
./download-repo-raw.sh octocat/Hello-World main files.txt ./my-output

# 平行下載 (8 個同時)
PARALLEL=8 ./download-repo-raw.sh octocat/Hello-World main files.txt
```

### Windows (PowerShell)

```powershell
# 基本用法
.\download-repo-raw.ps1 -Repo "octocat/Hello-World" -Branch "main" -FileList "files.txt"

# 指定輸出目錄 + 平行下載
.\download-repo-raw.ps1 -Repo "octocat/Hello-World" -Branch "main" -FileList "files.txt" -OutputDir ".\my-output" -Parallel 8
```

### 參數

| 參數 | 必填 | 說明 | 範例 |
|------|------|------|------|
| `owner/repo` | 是 | GitHub 儲存庫 | `octocat/Hello-World` |
| `branch` | 是 | 分支名稱 | `main` |
| `file-list` | 是 | 檔案清單路徑 | `files.txt` |
| `output_dir` | 否 | 輸出目錄 (預設：當前目錄) | `./my-output` |
| `PARALLEL` | 否 | 平行下載數量 (Bash 用環境變數) | `8` |
| `-Parallel` | 否 | 平行下載數量 (PowerShell 參數，預設 4) | `8` |

### 檔案清單格式

- 每行一個檔案相對路徑
- 支援 `#` 開頭的註解行
- 空行會自動忽略

```text
# 原始碼
src/main.py
src/utils.py

# 設定檔
config/settings.yaml

# 文件
README.md
```

### 運作原理

```
raw.githubusercontent.com/{owner}/{repo}/{branch}/{filepath}
```

## 系統需求

### Linux / macOS

- `curl`
- `tar` (codeload 方式)
- Bash 4+

### Windows

- PowerShell 5.1+ (Windows 內建) 或 PowerShell 7+
- PowerShell 7+ 支援 `-Parallel` 平行下載

## 限制

- 僅支援 **public** 儲存庫
- `raw` 方式需要使用者自行提供檔案清單（因為不使用 API 無法自動列舉 repo 內容）
- GitHub 有速率限制，大量下載可能被暫時封鎖
