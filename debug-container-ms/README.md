# debug-container-ms

Microsoft 支援的網路疑難排解容器 — 基於 **Azure Linux 3.0** (`mcr.microsoft.com/azurelinux/base/core:3.0`)。

專為 Azure 環境（AKS、Azure Container Instances、Azure Container Apps 等）設計的網路診斷工具箱，使用受 Microsoft 維護的 Azure Linux 作為基礎映像，套件管理採用 `tdnf` (RPM-based)，確保安全更新與官方支援。

## 特色

- **Azure Linux 3.0** — Microsoft 官方維護的容器基礎映像，glibc-based
- **安全導向** — 刻意移除高風險偵察/攻擊工具（nmap、openssh-clients 等）
- **精簡 Shell** — 使用 bash + 最小化 `.bashrc`，無額外 shell 框架相依性
- **deadman 整合** — 內建 [upa/deadman](https://github.com/upa/deadman) ping 監控工具，支援掛載自訂設定檔
- **vim 調校** — 內建精簡 `.vimrc`，提升終端機編輯效率

## 包含的工具

### 透過 tdnf 安裝
```
bash, bind-utils (dig/nslookup/host), conntrack-tools, curl,
ethtool, file, git, iproute (ip/ss), iputils (ping/traceroute), jq, mtr,
nmap-ncat (ncat), openssl, procps-ng (ps/top), python3,
python3-pip, socat, strace, tcpdump, traceroute, util-linux, vim,
iperf3, perl
```

### 透過 tdnf 嘗試安裝（可能依版本而異）
```
fping, ltrace, tcptraceroute, bridge-utils, httpd-tools (ab),
ipset, iptables, net-snmp-utils (snmpwalk/snmpget), nftables, wireshark-cli (tshark),
perl-Net-SSLeay, wget
```

> **確認不可用**: `tshark`/`wireshark-cli`, `iftop`, `ngrep` 在 Azure Linux 3.0 中無此套件。使用 `tcpdump` 作為替代。

### 透過 pip 安裝
```
httpie, scapy, speedtest-cli
```

### 從 GitHub Release 下載的二進位
```
ctop, termshark, grpcurl, fortio, trippy, websocat
```

### 從 GitHub Clone 安裝
```
deadman (github.com/upa/deadman) — curses-based ping 監控工具
```

## deadman 使用方式

[deadman](https://github.com/upa/deadman) 是 curses-based 的 ping 監控工具，適合用於活動網路 / 臨時網路的主機狀態監控。

### 預設設定檔

容器內建的預設設定檔位於 `/etc/deadman/deadman.conf`，直接執行即可使用：

```bash
# 使用內建預設設定檔
docker run -it --rm <ACR_NAME>.azurecr.io/debug-container-ms deadman /etc/deadman/deadman.conf
```

### 掛載自訂設定檔

建立您自己的 `deadman.conf` 後，透過 volume mount 掛載至容器內：

```bash
# 掛載自訂設定檔到預設路徑（覆蓋內建設定）
docker run -it --rm \
  -v ./my-deadman.conf:/etc/deadman/deadman.conf:ro \
  <ACR_NAME>.azurecr.io/debug-container-ms deadman /etc/deadman/deadman.conf

# 或掛載到任意路徑
docker run -it --rm \
  -v ./my-deadman.conf:/tmp/deadman.conf:ro \
  <ACR_NAME>.azurecr.io/debug-container-ms deadman /tmp/deadman.conf
```

### Kubernetes 中使用 ConfigMap 掛載

```bash
# 從檔案建立 ConfigMap
kubectl create configmap deadman-conf --from-file=deadman.conf=./my-deadman.conf

# 執行並掛載
kubectl run deadman-monitor --rm -i --tty \
  --image=<ACR_NAME>.azurecr.io/debug-container-ms \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "deadman-monitor",
        "image": "<ACR_NAME>.azurecr.io/debug-container-ms",
        "command": ["deadman", "/etc/deadman/deadman.conf"],
        "stdin": true, "tty": true,
        "volumeMounts": [{"name": "conf", "mountPath": "/etc/deadman/deadman.conf", "subPath": "deadman.conf"}]
      }],
      "volumes": [{"name": "conf", "configMap": {"name": "deadman-conf"}}]
    }
  }'
```

### deadman.conf 範例

```
# 基本格式：名稱<TAB>IP位址
googleDNS       8.8.8.8
cloudflare      1.1.1.1
quad9           9.9.9.9
---
googleDNS-v6    2001:4860:4860::8888
cloudflare-v6   2606:4700:4700::1111
```

> 詳細設定語法請參考 [upa/deadman README](https://github.com/upa/deadman)

## 使用方式

### Docker

```bash
# 進入容器的 network namespace 進行疑難排解
docker run -it --net container:<container_name> <ACR_NAME>.azurecr.io/debug-container-ms

# 進入 host 的 network namespace
docker run -it --net host <ACR_NAME>.azurecr.io/debug-container-ms

# 執行特定工具
docker run --rm <ACR_NAME>.azurecr.io/debug-container-ms tcpdump -i eth0 -c 10
docker run --rm <ACR_NAME>.azurecr.io/debug-container-ms curl -s https://ifconfig.me
```

### Kubernetes

```bash
# Ephemeral container 偵錯現有 Pod
kubectl debug mypod -it --image=<ACR_NAME>.azurecr.io/debug-container-ms

# 啟動一次性偵錯 Pod
kubectl run tmp-shell --rm -i --tty --image=<ACR_NAME>.azurecr.io/debug-container-ms

# 使用 host 的 network namespace
kubectl run tmp-shell --rm -i --tty \
  --overrides='{"spec": {"hostNetwork": true}}' \
  --image=<ACR_NAME>.azurecr.io/debug-container-ms

# 作為 sidecar container
```

### Docker Compose

```yaml
version: "3.6"
services:
  netshoot:
    image: <ACR_NAME>.azurecr.io/debug-container-ms
    depends_on:
      - nginx
    command: tcpdump -i eth0 -w /data/nginx.pcap
    network_mode: service:nginx
    volumes:
      - ./data:/data

  nginx:
    image: nginx:alpine
    ports:
      - 80:80
```

## 建構

### 前置需求

- Docker 20.10+
- Azure CLI（推送至 ACR 時需要）

### 本地建構

```bash
cd debug-container-ms

# 建構映像（需指定 ACR_NAME）
make build ACR_NAME=myacr

# 登入 ACR 並推送
make push ACR_NAME=myacr

# 一次完成建構 + 推送
make all ACR_NAME=myacr
```

### 驗證工具

```bash
# 執行工具驗證腳本
docker run --rm <ACR_NAME>.azurecr.io/debug-container-ms bash /root/test/validate-tools.sh
```

## CI/CD

專案提供 GitHub Actions workflow（`.github/workflows/build-push.yml`），支援：

- **自動觸發**：push 到 `main` 分支且 `debug-container-ms/` 路徑有變更時
- **手動觸發**：workflow_dispatch，可指定 ACR 名稱

需設定以下 GitHub Secrets：
- `AZURE_CLIENT_ID` — Azure AD 應用程式（client）ID
- `AZURE_TENANT_ID` — Azure AD 租戶 ID
- `AZURE_SUBSCRIPTION_ID` — Azure 訂用帳戶 ID
- `ACR_NAME` — Azure Container Registry 名稱（不含 .azurecr.io）

## 授權

MIT License
