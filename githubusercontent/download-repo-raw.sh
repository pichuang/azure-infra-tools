#!/usr/bin/env bash
#
# download-repo-raw.sh
#
# 透過 raw.githubusercontent.com 根據檔案清單逐檔下載 GitHub public repo 的檔案，
# 不使用 git clone、不使用 github.com 網址、不使用 GitHub API。
#
# 用法:
#   ./download-repo-raw.sh <owner/repo> <branch> <file-list.txt> [output_dir]
#
# file-list.txt 格式 (每行一個相對路徑):
#   README.md
#   src/main.py
#   docs/guide.md
#
# 範例:
#   ./download-repo-raw.sh octocat/Hello-World main files.txt
#   ./download-repo-raw.sh octocat/Hello-World main files.txt ./my-output
#
# 進階: 平行下載 (需要 xargs 支援 -P):
#   PARALLEL=8 ./download-repo-raw.sh octocat/Hello-World main files.txt
#

set -euo pipefail

# ---------------------------------------------------------------------------
# 顏色輸出
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }

# ---------------------------------------------------------------------------
# 參數檢查
# ---------------------------------------------------------------------------
if [[ $# -lt 3 ]]; then
    echo "用法: $0 <owner/repo> <branch> <file-list.txt> [output_dir]"
    echo ""
    echo "參數:"
    echo "  owner/repo      GitHub 儲存庫，例如 octocat/Hello-World"
    echo "  branch          分支名稱，例如 main"
    echo "  file-list.txt   檔案清單，每行一個相對路徑"
    echo "  output_dir      (選填) 輸出目錄，預設為當前目錄"
    echo ""
    echo "環境變數:"
    echo "  PARALLEL         平行下載數量 (預設: 1，建議 4-8)"
    echo ""
    echo "範例:"
    echo "  $0 octocat/Hello-World main files.txt"
    echo "  PARALLEL=8 $0 octocat/Hello-World main files.txt ./output"
    exit 1
fi

REPO="$1"
BRANCH="$2"
FILE_LIST="$3"
OUTPUT_DIR="${4:-.}"
PARALLEL="${PARALLEL:-1}"

# 驗證 owner/repo 格式
if [[ ! "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    error "儲存庫格式不正確，應為 owner/repo，例如 octocat/Hello-World"
    exit 1
fi

# 驗證檔案清單存在
if [[ ! -f "$FILE_LIST" ]]; then
    error "檔案清單不存在: $FILE_LIST"
    exit 1
fi

# 驗證檔案清單不為空
if [[ ! -s "$FILE_LIST" ]]; then
    error "檔案清單是空的: $FILE_LIST"
    exit 1
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

# ---------------------------------------------------------------------------
# 檢查相依工具
# ---------------------------------------------------------------------------
if ! command -v curl &>/dev/null; then
    error "找不到必要工具: curl，請先安裝。"
    exit 1
fi

# ---------------------------------------------------------------------------
# 建立輸出目錄
# ---------------------------------------------------------------------------
mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------------------
# 單檔下載函式
# ---------------------------------------------------------------------------
download_single_file() {
    local filepath="$1"
    local owner="$2"
    local repo_name="$3"
    local branch="$4"
    local output_dir="$5"

    # 跳過空行和註解行
    [[ -z "$filepath" || "$filepath" =~ ^[[:space:]]*# ]] && return 0

    # 移除前後空白
    filepath=$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$filepath" ]] && return 0

    local url="https://raw.githubusercontent.com/${owner}/${repo_name}/${branch}/${filepath}"
    local dest="${output_dir}/${filepath}"
    local dest_dir
    dest_dir=$(dirname "$dest")

    # 建立目標目錄
    mkdir -p "$dest_dir"

    # 下載檔案
    local http_code
    http_code=$(curl -sS -w "%{http_code}" -L -o "$dest" "$url")

    if [[ "$http_code" -eq 200 ]]; then
        printf "${GREEN}[OK]${NC}    %s\n" "$filepath"
        return 0
    else
        printf "${RED}[FAIL]${NC}  %s (HTTP %s)\n" "$filepath" "$http_code"
        rm -f "$dest"
        return 1
    fi
}

# 匯出函式和變數，讓 xargs 子程序可以使用
export -f download_single_file
export RED GREEN YELLOW NC

# ---------------------------------------------------------------------------
# 下載
# ---------------------------------------------------------------------------
TOTAL_FILES=$(grep -cvE '^\s*(#|$)' "$FILE_LIST" || true)
info "儲存庫:   ${OWNER}/${REPO_NAME}"
info "分支:     ${BRANCH}"
info "檔案數量: ${TOTAL_FILES}"
info "平行數:   ${PARALLEL}"
info "輸出目錄: $(cd "$OUTPUT_DIR" && pwd)"
echo ""

SUCCESS=0
FAIL=0

if [[ "$PARALLEL" -gt 1 ]]; then
    # 平行下載模式
    xargs -P "$PARALLEL" -I {} bash -c \
        'download_single_file "$@"' _ {} "$OWNER" "$REPO_NAME" "$BRANCH" "$OUTPUT_DIR" \
        < "$FILE_LIST"

    # 平行模式下的計數 (重新檢查檔案是否存在)
    while IFS= read -r filepath || [[ -n "$filepath" ]]; do
        [[ -z "$filepath" || "$filepath" =~ ^[[:space:]]*# ]] && continue
        filepath=$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$filepath" ]] && continue
        if [[ -f "${OUTPUT_DIR}/${filepath}" ]]; then
            SUCCESS=$((SUCCESS + 1))
        else
            FAIL=$((FAIL + 1))
        fi
    done < "$FILE_LIST"
else
    # 逐檔下載模式
    while IFS= read -r filepath || [[ -n "$filepath" ]]; do
        if download_single_file "$filepath" "$OWNER" "$REPO_NAME" "$BRANCH" "$OUTPUT_DIR"; then
            # 只計數非空行非註解行
            [[ -z "$filepath" || "$filepath" =~ ^[[:space:]]*# ]] || SUCCESS=$((SUCCESS + 1))
        else
            FAIL=$((FAIL + 1))
        fi
    done < "$FILE_LIST"
fi

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------
echo ""
info "下載完成！"
info "成功: ${SUCCESS}，失敗: ${FAIL}，共 ${TOTAL_FILES} 個檔案"

if [[ "$FAIL" -gt 0 ]]; then
    warn "有 ${FAIL} 個檔案下載失敗，請檢查檔案路徑是否正確"
    exit 1
fi
