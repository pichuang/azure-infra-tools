#!/usr/bin/env bash
#
# download-repo-codeload.sh
#
# 透過 codeload.githubusercontent.com 下載 GitHub public repo 特定 branch 的完整壓縮檔，
# 不使用 git clone、不使用 github.com 網址、不使用 GitHub API。
#
# 用法:
#   ./download-repo-codeload.sh <owner/repo> <branch> [output_dir]
#
# 範例:
#   ./download-repo-codeload.sh octocat/Hello-World main
#   ./download-repo-codeload.sh octocat/Hello-World main ./my-output
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
if [[ $# -lt 2 ]]; then
    echo "用法: $0 <owner/repo> <branch> [output_dir]"
    echo ""
    echo "參數:"
    echo "  owner/repo   GitHub 儲存庫，例如 octocat/Hello-World"
    echo "  branch       分支名稱，例如 main"
    echo "  output_dir   (選填) 輸出目錄，預設為當前目錄"
    echo ""
    echo "範例:"
    echo "  $0 octocat/Hello-World main"
    echo "  $0 octocat/Hello-World main ./my-output"
    exit 1
fi

REPO="$1"
BRANCH="$2"
OUTPUT_DIR="${3:-.}"

# 驗證 owner/repo 格式
if [[ ! "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    error "儲存庫格式不正確，應為 owner/repo，例如 octocat/Hello-World"
    exit 1
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

# ---------------------------------------------------------------------------
# 檢查相依工具
# ---------------------------------------------------------------------------
for cmd in curl tar; do
    if ! command -v "$cmd" &>/dev/null; then
        error "找不到必要工具: $cmd，請先安裝。"
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# 建立輸出目錄
# ---------------------------------------------------------------------------
mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------------------
# 下載 tar.gz (嘗試多種 URL 格式)
# ---------------------------------------------------------------------------
URLS=(
    "https://codeload.githubusercontent.com/${OWNER}/${REPO_NAME}/tar.gz/refs/heads/${BRANCH}"
    "https://codeload.githubusercontent.com/${OWNER}/${REPO_NAME}/tar.gz/${BRANCH}"
    "https://codeload.githubusercontent.com/${OWNER}/${REPO_NAME}/legacy.tar.gz/refs/heads/${BRANCH}"
)

TEMP_FILE=$(mktemp "${TMPDIR:-/tmp}/github-download-XXXXXX.tar.gz")

# 確保結束時清理暫存檔
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

info "輸出目錄: $(cd "$OUTPUT_DIR" && pwd)"

HTTP_CODE=""
USED_URL=""
for url in "${URLS[@]}"; do
    info "嘗試下載: ${url}"
    HTTP_CODE=$(curl -sS -w "%{http_code}" -L -o "$TEMP_FILE" "$url")
    if [[ "$HTTP_CODE" -eq 200 ]]; then
        USED_URL="$url"
        break
    fi
    warn "HTTP ${HTTP_CODE}，嘗試下一個 URL..."
done

if [[ "$HTTP_CODE" -ne 200 ]]; then
    error "所有 URL 格式都下載失敗"
    case "$HTTP_CODE" in
        404) error "找不到儲存庫或分支: ${OWNER}/${REPO_NAME} @ ${BRANCH}" ;;
        403) error "存取被拒絕，可能是 private repo 或觸發速率限制" ;;
        *)   error "最後一次 HTTP 狀態碼: ${HTTP_CODE}" ;;
    esac
    exit 1
fi

info "下載成功: ${USED_URL}"

# 驗證下載檔案大小
FILE_SIZE=$(wc -c < "$TEMP_FILE" | tr -d ' ')
if [[ "$FILE_SIZE" -lt 100 ]]; then
    error "下載的檔案過小 (${FILE_SIZE} bytes)，可能是空的或損壞的"
    exit 1
fi

# ---------------------------------------------------------------------------
# 解壓縮
# ---------------------------------------------------------------------------
info "解壓縮中..."

# codeload 的 tar.gz 會有一個頂層目錄 {repo_name}-{branch}/
# 使用 --strip-components=1 把頂層目錄去掉，直接放到輸出目錄
tar -xzf "$TEMP_FILE" -C "$OUTPUT_DIR" --strip-components=1

info "完成！檔案已下載至: $(cd "$OUTPUT_DIR" && pwd)"

# 顯示檔案統計
FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')
DIR_COUNT=$(find "$OUTPUT_DIR" -type d | wc -l | tr -d ' ')
info "共 ${FILE_COUNT} 個檔案，${DIR_COUNT} 個目錄"
