# =============================================================================
# Nginx Health Probe Container
# =============================================================================
# Base Image : mcr.microsoft.com/azurelinux/base/nginx:1.28 (Azure Linux 3.0)
# Purpose    : Lightweight health probe returning JSON via pure nginx
# Ports      : 8080 (HTTP), 8443 (HTTPS-ready)
# User       : nginx (non-root, UID 999)
# Note       : Use host-side port mapping for standard ports:
#              docker run -p 80:8080 -p 443:8443 ...
# =============================================================================

FROM mcr.microsoft.com/azurelinux/base/nginx:1.28

LABEL maintainer="pichuang" \
      description="Nginx health probe endpoint for network connectivity diagnostics" \
      org.opencontainers.image.base.name="mcr.microsoft.com/azurelinux/base/nginx:1.28"

# Remove default server block; replaced by our custom config
RUN rm -f /etc/nginx/nginx.conf.default

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Prepare directories for rootless execution:
#   - /tmp/*_temp   : nginx temp file paths (client body, proxy, fastcgi, etc.)
#   - /var/log/nginx: log directory (symlinked to /var/opt/nginx/log)
#   - /tmp/nginx.pid: PID file location (writable by non-root)
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

# Run as non-root user — no CAP_NET_BIND_SERVICE required
USER nginx

# Container health check — uses curl (built into Azure Linux base image)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["curl", "-sf", "http://localhost:8080/healthz"]

# Start nginx in foreground mode (required for container use)
CMD ["nginx", "-g", "daemon off;"]
