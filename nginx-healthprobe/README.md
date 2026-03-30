# Nginx Health Probe

輕量級 Nginx 容器，提供 `/healthz` JSON endpoint，回傳網路連線診斷資訊（來源 IP、觸發時間、User Agent 等），協助使用者快速驗證網路是否通順。

## 特色

- **純 Nginx 方案** — 不依賴額外後端服務或模組（njs、Lua 等），零額外相依性
- **Rootless 容器** — 以非 root 使用者執行，容器內監聽 port 8080 / 8443（非特權 port），透過 port mapping 對外提供 80 / 443，同時支援 Docker 與 Podman
- **最小安裝** — 無額外安裝套件（不需要 libcap/setcap），零維護成本
- **輕量映像** — 基於 `mcr.microsoft.com/azurelinux/base/nginx:1.28`（Microsoft Azure Linux）
- **JSON 回應** — 所有 endpoint 回傳結構化 JSON（含 `http_status` 欄位），方便 `curl` + `jq` 或程式解析
- **安全強化** — 隱藏 server tokens、唯讀檔案系統、禁止提權
- **速率限制** — 內建每 IP 每秒 10 次請求限制，防範短時間大量查詢，超過自動回傳 429 並標記為疑似攻擊
- **請求反射** — `/return` endpoint 回傳用戶端所有常見 HTTP headers 與請求資訊，方便除錯

## 快速啟動

### Docker

```bash
# 建構映像
docker build -t nginx-healthprobe .

# 啟動容器（容器內 8080/8443 映射至主機 80/443）
docker run -d --name nginx-healthprobe -p 80:8080 -p 443:8443 nginx-healthprobe

# 測試（直接 curl 即可，不需要指定路徑）
curl -s http://localhost/ | jq .
curl -s http://localhost:443/ | jq .
```

### Podman (Rootless)

```bash
# 建構映像
podman build -t nginx-healthprobe .

# 啟動容器（容器內 8080/8443 映射至主機 80/443）
podman run -d --name nginx-healthprobe -p 80:8080 -p 443:8443 nginx-healthprobe

# 測試
curl -s http://localhost/ | jq .
curl -s http://localhost:443/ | jq .
```

### Docker Compose

```bash
docker compose up -d

# 測試
curl -s http://localhost/ | jq .
```

## 範例輸出

```bash
$ curl -s http://localhost/ | jq .
```

```json
{
  "status": "healthy",
  "http_status": 200,
  "timestamp": "2026-03-30T10:15:30+00:00",
  "client_ip": "172.17.0.1",
  "client_port": "54321",
  "x_forwarded_for": "",
  "request_method": "GET",
  "request_uri": "/",
  "http_host": "localhost",
  "user_agent": "curl/8.5.0",
  "http_version": "HTTP/1.1",
  "accept_encoding": "gzip, deflate",
  "accept": "*/*"
}
```

使用 `wget` 測試：

```bash
wget -qO- http://localhost/ | jq .
```

### 請求反射

**GET 請求：**

```bash
$ curl -s http://localhost/return | jq .
```

```json
{
  "http_status": 200,
  "timestamp": "2026-03-30T10:15:30+00:00",
  "request": {
    "method": "GET",
    "uri": "/return",
    "url": "http://localhost/return",
    "http_version": "HTTP/1.1",
    "content_type": "",
    "content_length": ""
  },
  "headers": {
    "host": "localhost",
    "user_agent": "curl/8.5.0",
    "accept": "*/*",
    "accept_encoding": "gzip, deflate",
    "accept_language": "",
    "connection": "keep-alive",
    "cache_control": "",
    "pragma": "",
    "referer": "",
    "origin": "",
    "x_forwarded_for": "",
    "x_forwarded_proto": "",
    "x_forwarded_host": "",
    "x_real_ip": "",
    "x_request_id": "",
    "authorization": ""
  },
  "client": {
    "ip": "172.17.0.1",
    "port": "54322"
  }
}
```

**POST 請求：**

```bash
$ curl -s -X POST http://localhost/return \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' | jq .
```

```json
{
  "http_status": 200,
  "timestamp": "2026-03-30T10:15:32+00:00",
  "request": {
    "method": "POST",
    "uri": "/return",
    "url": "http://localhost/return",
    "http_version": "HTTP/1.1",
    "content_type": "application/json",
    "content_length": "16"
  },
  "headers": {
    "host": "localhost",
    "user_agent": "curl/8.5.0",
    "accept": "*/*",
    "accept_encoding": "gzip, deflate",
    "accept_language": "",
    "connection": "keep-alive",
    "cache_control": "",
    "pragma": "",
    "referer": "",
    "origin": "",
    "x_forwarded_for": "",
    "x_forwarded_proto": "",
    "x_forwarded_host": "",
    "x_real_ip": "",
    "x_request_id": "",
    "authorization": ""
  },
  "client": {
    "ip": "172.17.0.1",
    "port": "54323"
  }
}
```

> **備註**：因本專案採用純 Nginx 方案（不依賴 njs/Lua），POST request body 不會被反射回來，但 `request.method`、`request.content_type`、`request.content_length` 及所有 headers 均會完整反射。

### 速率限制觸發範例

當同一 IP 短時間內大量請求超過限制時，回傳 429：

```json
{
  "error": "too_many_requests",
  "http_status": 429,
  "message": "Rate limit exceeded. You have been flagged as a suspected attacker.",
  "timestamp": "2026-03-30T10:15:35+00:00",
  "client_ip": "172.17.0.1"
}
```

## 欄位說明

### 健康探測回應（`/`、`/healthz`）

| 欄位 | 說明 | 用途 |
|------|------|------|
| `status` | 服務狀態 (`healthy`) | 確認服務正常運作 |
| `http_status` | HTTP 狀態碼 | 方便程式解析回應狀態 |
| `timestamp` | ISO 8601 格式時間戳記 | 確認請求觸發的精確時間 |
| `client_ip` | 請求端的來源 IP | **辨識自身 IP / 驗證網路路由** |
| `client_port` | 請求端的來源 Port | 辨識連線來源 |
| `x_forwarded_for` | 代理轉發的原始 IP 鏈 | 在反向代理後追蹤真實來源 IP |
| `request_method` | HTTP 請求方法 | 確認請求類型 |
| `request_uri` | 請求的 URI 路徑 | 確認請求路徑 |
| `http_host` | HTTP Host header | 確認請求的目標主機 |
| `user_agent` | 用戶端 User Agent | 辨識用戶端工具 (curl/wget/瀏覽器) |
| `http_version` | HTTP 協議版本 | 確認使用的 HTTP 版本 |
| `accept_encoding` | 用戶端支援的編碼方式 | 確認壓縮編碼（gzip, deflate, br 等） |
| `accept` | 用戶端接受的 MIME 類型 | 確認請求期望的回應格式 |

### 請求反射回應（`/return`）

| 欄位 | 說明 |
|------|------|
| `http_status` | HTTP 狀態碼 |
| `timestamp` | ISO 8601 格式時間戳記 |
| `request.*` | 請求資訊（method、uri、url、http_version、content_type、content_length） |
| `headers.*` | 用戶端傳出的所有常見 HTTP headers（含 proxy 相關 header 與 authorization） |
| `client.*` | 用戶端連線資訊（ip、port） |

## Endpoints

| 路徑 | 方法 | HTTP 狀態碼 | 說明 |
|------|------|------------|------|
| `/` | GET | 200 | 回傳 JSON 健康探測資訊 |
| `/healthz` | GET | 200 | 回傳 JSON 健康探測資訊（相容路徑） |
| `/return` | GET, POST | 200 | 請求反射 — 回傳用戶端所有 HTTP headers 與請求資訊 |
| 其他路徑 | 任意 | 404 | JSON 錯誤訊息，列出可用 endpoint |
| 任意（速率限制觸發） | 任意 | 429 | JSON 錯誤訊息，含 `Retry-After` header |

### 監聽 Port

| 主機 Port | 容器 Port | 說明 |
|-----------|-----------|------|
| `80` | `8080` | HTTP 標準 port |
| `443` | `8443` | HTTPS 標準 port（目前為 HTTP，如需 TLS 請自行設定） |

> 容器內使用非特權 port（>1024），不需要額外安裝 `libcap` 或設定 `setcap`，透過 `-p 80:8080` 映射至主機標準 port。

## 使用範例

以下假設服務運行於 `http://<SERVER_IP>`，請將 `<SERVER_IP>` 替換為實際的伺服器 IP 或 FQDN。

### 基本查詢

```bash
# 直接 curl 網址即可（不需指定路徑）
curl -s http://<SERVER_IP>/ | jq .

# 使用 443 port
curl -s http://<SERVER_IP>:443/ | jq .

# /healthz 路徑同樣有效
curl -s http://<SERVER_IP>/healthz | jq .

# 請求反射 — 查看完整 HTTP headers（GET）
curl -s http://<SERVER_IP>/return | jq .

# 請求反射 — POST 方式
curl -s -X POST http://<SERVER_IP>/return \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}' | jq .

# 不使用 jq，直接查看原始 JSON
curl -s http://<SERVER_IP>/
```

### 只取特定欄位

```bash
# 只看自己的來源 IP
curl -s http://<SERVER_IP>/ | jq -r '.client_ip'

# 只看時間戳記
curl -s http://<SERVER_IP>/ | jq -r '.timestamp'

# 同時取得 IP 和時間
curl -s http://<SERVER_IP>/ | jq '{client_ip, timestamp}'

# 取得編碼與 MIME 類型資訊
curl -s http://<SERVER_IP>/ | jq '{accept_encoding, accept}'
```

### 含 HTTP Header 的詳細輸出

```bash
# 顯示回應 header + body
curl -i http://<SERVER_IP>/

# 顯示完整請求/回應過程（Debug 用）
curl -v http://<SERVER_IP>/
```

### 搭配 wget 使用

```bash
# 基本查詢
wget -qO- http://<SERVER_IP>/ | jq .

# 只看來源 IP
wget -qO- http://<SERVER_IP>/ | jq -r '.client_ip'
```

### 連線測試腳本（持續監控）

```bash
# 每 5 秒探測一次，印出時間和來源 IP
while true; do
  curl -s http://<SERVER_IP>/ | jq -r '[.timestamp, .client_ip] | join(" | ")'
  sleep 5
done
```

### PowerShell (Windows)

```powershell
# 基本查詢
Invoke-RestMethod -Uri "http://<SERVER_IP>/"

# 只看來源 IP
(Invoke-RestMethod -Uri "http://<SERVER_IP>/").client_ip

# 格式化 JSON 輸出
Invoke-RestMethod -Uri "http://<SERVER_IP>/" | ConvertTo-Json
```

### 判斷連線是否正常（用於自動化腳本）

```bash
# 回傳 0 表示連線正常，非 0 表示異常
if curl -sf http://<SERVER_IP>/ > /dev/null; then
  echo "✅ 網路連線正常"
else
  echo "❌ 無法連線至 health probe"
fi
```

## 前置需求

### RHEL / CentOS / Fedora

```bash
# Docker
sudo dnf install -y docker
sudo systemctl enable --now docker

# 或 Podman (通常已預裝)
sudo dnf install -y podman
```

### Ubuntu / Debian

```bash
# Docker (官方安裝方式)
# 參考: https://docs.docker.com/engine/install/ubuntu/

# 或 Podman
sudo apt-get update && sudo apt-get install -y podman
```

## 客製化

### 更換 Port

修改 `docker-compose.yml` 中的 port mapping：

```yaml
ports:
  - "自訂Port:8080"
  - "自訂Port:8443"
```

或直接在 `docker run` / `podman run` 指定：

```bash
docker run -d -p 自訂Port:8080 -p 自訂Port:8443 nginx-healthprobe
```

### 修改回應內容

編輯 `nginx.conf` 中 `location /healthz` 區塊的 `return 200` 內容，可新增或移除欄位。Nginx 支援的內建變數清單請參考 [Nginx 官方文件](http://nginx.org/en/docs/http/ngx_http_core_module.html#variables)。

### 日誌持久化

日誌同時輸出至 stdout/stderr（方便 `docker logs` / `podman logs` 查看）及檔案（`/var/log/nginx/`），採用 JSON 稽核格式。透過 volume 可將日誌持久保存，容器更新或關閉後日誌不會遺失。

**Docker Compose**（已內建於 `docker-compose.yml`，使用 named volume）：

```yaml
volumes:
  - nginx-logs:/var/log/nginx
```

**Docker（使用 named volume，推薦）**：

```bash
docker run -d --name nginx-healthprobe \
  -p 80:8080 -p 443:8443 \
  -v nginx-healthprobe-logs:/var/log/nginx \
  nginx-healthprobe
```

**Docker（使用主機目錄映射）**：

```bash
sudo mkdir -p /var/log/nginx-healthprobe
docker run -d --name nginx-healthprobe \
  -p 80:8080 -p 443:8443 \
  -v /var/log/nginx-healthprobe:/var/log/nginx \
  nginx-healthprobe
```

**Podman（使用主機目錄映射）**：

> Podman rootless 模式下需加上 `:U` 旗標，自動調整目錄擁有者以匹配容器使用者。

```bash
sudo mkdir -p /var/log/nginx-healthprobe
podman run -d --name nginx-healthprobe \
  -p 80:8080 -p 443:8443 \
  -v /var/log/nginx-healthprobe:/var/log/nginx:U \
  nginx-healthprobe
```

日誌檔案（JSON 稽核格式，每行一筆）：
- `access.log` — 存取日誌，包含 timestamp、client_ip、request_method、request_uri、user_agent 等稽核欄位
- `error.log` — 錯誤日誌（warn 等級以上）

查詢範例：

```bash
# 查看所有存取日誌
cat /var/log/nginx-healthprobe/access.log | jq .

# 查詢特定 IP 的所有請求
cat /var/log/nginx-healthprobe/access.log | jq 'select(.client_ip == "10.0.0.1")'

# 查詢特定時間範圍的請求
cat /var/log/nginx-healthprobe/access.log | jq 'select(.timestamp > "2026-03-30T12:00")'

# 查詢所有疑似攻擊者的請求（觸發速率限制）
cat /var/log/nginx-healthprobe/access.log | jq 'select(.suspected_attack == "true")'

# 統計各 IP 觸發速率限制的次數
cat /var/log/nginx-healthprobe/access.log | jq -r 'select(.suspected_attack == "true") | .client_ip' | sort | uniq -c | sort -rn
```

## 速率限制與安全防護

內建基於 IP 的速率限制機制，防範短時間大量查詢：

| 參數 | 值 | 說明 |
|------|-----|------|
| `rate` | 10r/s | 每個 IP 每秒最多 10 次請求 |
| `burst` | 20 | 允許瞬間突發最多 20 個額外請求 |
| `nodelay` | - | 超過 burst 立即拒絕，不排隊等待 |
| 拒絕狀態碼 | 429 | Too Many Requests |
| `Retry-After` | 1 | 建議用戶端 1 秒後重試 |

### 日誌標記

當請求觸發速率限制（HTTP 429）時，稽核日誌會自動在該筆記錄加上 `"suspected_attack":"true"` 標記，方便後續使用 ELK / Azure Monitor / Grafana 等工具篩選與告警：

```json
{
  "timestamp": "2026-03-30T10:15:35+00:00",
  "client_ip": "10.0.0.1",
  "status": 429,
  "suspected_attack": "true",
  "...": "..."
}
```

### 自訂速率限制

編輯 `nginx.conf` 中的 `limit_req_zone` 參數可調整限制策略：

```nginx
# 放寬至每秒 50 次
 limit_req_zone $binary_remote_addr zone=req_limit:10m rate=50r/s;

# 在 server 區塊調整 burst
limit_req zone=req_limit burst=100 nodelay;
```

## 授權

MIT License
