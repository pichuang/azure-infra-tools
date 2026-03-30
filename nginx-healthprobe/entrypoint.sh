#!/bin/sh
# =============================================================================
# 容器啟動入口腳本
# =============================================================================
# 處理 volume mount 時日誌目錄權限問題：
#   主機端掛載的目錄可能歸 root 所有，nginx 使用者（UID 999）無法寫入。
#   此腳本以 root 修正權限後，由 nginx master process 透過
#   nginx.conf 中的 "user nginx" 指令將 worker 降權至 nginx 使用者。
# =============================================================================

LOG_DIR="/var/log/nginx"

# 以 root 修正日誌目錄權限
chown -R nginx:nginx "$LOG_DIR" 2>/dev/null
touch "$LOG_DIR/access.log" "$LOG_DIR/error.log" 2>/dev/null
chown nginx:nginx "$LOG_DIR/access.log" "$LOG_DIR/error.log" 2>/dev/null

# 確保 /tmp 目錄下的暫存檔和 PID 檔可由 nginx 使用者寫入
# （read_only + tmpfs 模式下，build 階段的權限設定會被覆蓋）
# 注意：podman rootless 環境下 chown 到其他 UID 會導致 root 無法寫入，
#       因此使用 chmod 666 確保所有使用者都可讀寫
mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp 2>/dev/null
chmod 777 /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp 2>/dev/null
rm -f /tmp/nginx.pid 2>/dev/null
touch /tmp/nginx.pid 2>/dev/null
chmod 666 /tmp/nginx.pid 2>/dev/null

# 檢查日誌檔是否可寫入
if [ -w "$LOG_DIR/access.log" ]; then
    echo "[entrypoint] 日誌目錄權限正常，日誌將寫入 $LOG_DIR"
else
    echo "[entrypoint] 警告：無法寫入 $LOG_DIR，日誌僅輸出至 stdout/stderr"
    ln -sf /dev/stdout "$LOG_DIR/access.log" 2>/dev/null || true
    ln -sf /dev/stderr "$LOG_DIR/error.log" 2>/dev/null || true
fi

# 啟動 nginx（master 以 root 執行，worker 透過 nginx.conf 中 "user nginx" 降權）
exec nginx -g 'daemon off;'
