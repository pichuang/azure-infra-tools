# Azure Service Tag 外網 IP 查詢工具

本工具可查詢指定 Azure Service Tag 在特定區域與訂閱下的所有外網 IP 清單，亦可列出該區域所有可用的 Service Tag 名稱。

## 功能特色
- 查詢指定 Service Tag 的所有外網 IP
- 支援 CSV 或 JSON 格式輸出
- 可列出區域內所有 Service Tag 名稱

## 先決條件
- Python 3.9 以上
- 已安裝 Azure Python SDK（`azure-identity`, `azure-mgmt-network`）
- 具備查詢網路資源權限的 Azure 帳號

## 安裝方式
```sh
pip install azure-identity azure-mgmt-network
```

## 使用方式

### 查詢 Service Tag 的 IP 清單
```sh
python azure_service_tag_ip_query.py --service-tag AzureFrontDoor.Frontend --location japaneast --subscription-id <你的訂閱ID> --output csv
```
- `--service-tag`：Service Tag 名稱（預設：AzureFrontDoor.Frontend）
- `--location`：Azure 區域（預設：japaneast）
- `--subscription-id`：Azure 訂閱 ID
- `--output`：輸出格式，`csv` 或 `json`（預設 csv）

### 列出所有 Service Tag 名稱
```sh
python azure_service_tag_ip_query.py --list-tags --location japaneast --subscription-id <你的訂閱ID>
```

## 範例輸出
#### CSV
```
ip_prefix
13.107.246.40/32
13.107.213.40/32
...
```
#### JSON
```
[
  "13.107.246.40/32",
  "13.107.213.40/32",
  ...
]
```

## 授權
MIT
