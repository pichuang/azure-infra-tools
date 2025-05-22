# Azure Infra Tools

本專案為 Azure 基礎設施自動化、診斷與日常維運工具集合，協助雲端架構師、維運人員與開發者提升 Azure 管理效率。

## 工具總覽

- [Azure VM 維運工具](./azure-vm-maintenance/README.md)：查詢 VM 詳細資訊、自動建立磁碟快照、備份檢查等。
- [Azure 區域延遲/頻寬測試](./azure-zone-latency-bandwidth-test/README.md)：跨區域網路延遲與頻寬測試腳本。
- [Azure Service Tag IP 查詢](./azure-service-tag-ip-query/README_zh-TW.md)：查詢指定 Service Tag 的外網 IP 清單，支援多區域與格式。
- [Azure 防火牆規則原理圖](./azure-firewall-policies/500-private-aks-rules/README.md)：管理與套用 Azure Firewall Policy，含多種場景原理圖與範例。
- [Azure Container Image 匯入工具](./copy-container-images/README.md)：自動化將外部 container image 匯入 Azure Container Registry。
- [Network Watcher 工具](./network-watcher/README.md)：網路診斷、流量監控與拓撲視覺化。

## 目錄結構

- `azure-vm-maintenance/`：VM 維運腳本與自動化工具
- `azure-zone-latency-bandwidth-test/`：區域延遲/頻寬測試
- `azure-service-tag-ip-query/`：Service Tag IP 查詢工具
- `azure-firewall-policies/`：防火牆規則原理圖與範例
- `copy-container-images/`：Container image 匯入腳本
- `network-watcher/`：網路監控與診斷
- `dev/`：開發中或實驗性工具

## 安裝需求

- Python 3.9 以上（部分工具需 Azure Python SDK）
- Terraform（如需套用防火牆規則）
- 具備 Azure 權限的帳號

## 授權

MIT License

---

如需詳細使用方式，請參閱各子資料夾內 README。
