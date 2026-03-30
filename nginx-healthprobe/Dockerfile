# =============================================================================
# Nginx Health Probe 容器
# =============================================================================
# 基礎映像 : mcr.microsoft.com/azurelinux/base/nginx:1.28 (Azure Linux 3.0)
# 用途     : 透過純 nginx 提供輕量級 JSON 健康探測 endpoint
# Port     : 8080 (HTTP), 8443 (HTTPS-ready)
# 執行身分 : nginx (非 root, UID 999)，透過 entrypoint 腳本切換
# 備註     : 透過主機端 port mapping 對外提供標準 port：
#            docker run -p 80:8080 -p 443:8443 ...
# =============================================================================

FROM mcr.microsoft.com/azurelinux/base/nginx:1.28

LABEL maintainer="pichuang" \
      description="Nginx health probe endpoint for network connectivity diagnostics" \
      org.opencontainers.image.base.name="mcr.microsoft.com/azurelinux/base/nginx:1.28"

# 移除預設 server block，改用自訂設定
RUN rm -f /etc/nginx/nginx.conf.default

# 設定時區為 UTC+8（POSIX 格式，無需安裝 tzdata，適用於離線環境）
# POSIX TZ 中偏移量符號與 UTC 相反：UTC-8 代表 UTC+8
ENV TZ=UTC-8

# 複製自訂 nginx 設定檔
COPY nginx.conf /etc/nginx/nginx.conf

# 複製啟動入口腳本（處理 bind mount 權限問題後以 nginx 使用者啟動服務）
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 建立 rootless 執行所需的目錄並設定權限：
#   - /tmp/*_temp    : nginx 暫存檔路徑（client body、proxy、fastcgi 等）
#   - /var/log/nginx : 日誌目錄（symlink 至 /var/opt/nginx/log）
#   - /tmp/nginx.pid : PID 檔位置（非 root 可寫入）
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
             /tmp/uwsgi_temp /tmp/scgi_temp /var/opt/nginx/log \
    && chown -R nginx:nginx /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
                            /tmp/uwsgi_temp /tmp/scgi_temp \
    && chown -R nginx:nginx /var/log/nginx /var/opt/nginx \
    && touch /tmp/nginx.pid \
    && chown nginx:nginx /tmp/nginx.pid

# 使用非特權 port（>1024），不需額外安裝套件或設定 capabilities
#   8080 — HTTP
#   8443 — HTTPS（目前為 HTTP，掛載 TLS 憑證即可啟用 HTTPS）
# 對外映射至標準 port：docker run -p 80:8080 -p 443:8443
EXPOSE 8080 8443

# 宣告日誌目錄為 volume，方便掛載至主機持久化保存
VOLUME /var/log/nginx

# 不在此處設定 USER，由 entrypoint.sh 處理：
#   1. 以 root 修正 bind mount 日誌目錄權限
#   2. 再以 nginx 使用者身分啟動 nginx 服務

# 容器健康檢查 — 使用 Azure Linux 基礎映像內建的 curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["curl", "-sf", "http://localhost:8080/healthz"]

# 使用啟動入口腳本（修正權限後以 nginx 使用者執行）
ENTRYPOINT ["/entrypoint.sh"]
