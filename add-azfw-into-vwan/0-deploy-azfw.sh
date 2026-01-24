#!/bin/bash

# 設定變數
RG_NAME="rg-vdss-vwan-prd-global"
LOCATION="eastus"
HUB_NAME="vhub-vdss-az-prd-eus-01"
FW_NAME="afw-vdss-az-prd-eus-01"
POLICY_ID="/subscriptions/21e94c55-7048-401a-9976-539c88f75694/resourceGroups/rg-vdss-afwp-prd-global/providers/Microsoft.Network/firewallPolicies/afwp-global-01"

# 假設您的 Public IP 名稱如下 (可以是單個或多個)
PIP_NAME_1="pip-vdss-azfw-prd-eus-01"
# PIP_NAME_2="Customer-Provided-IP-02"

# 取得 Public IP 的 Resource ID (存入變數)
PIP_ID_1=$(az network public-ip show --name $PIP_NAME_1 --resource-group $RG_NAME --query id -o tsv)

# 若有多個 IP，請依此類推
# PIP_ID_2=$(az network public-ip show --name $PIP_NAME_2 --resource-group $RG_NAME --query id -o tsv)

echo "使用的 Public IP ID: $PIP_ID_1"

az network firewall create \
    --name $FW_NAME \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --sku AZFW_Hub \
    --tier Standard \
    --virtual-hub $HUB_NAME \
    --firewall-policy $POLICY_ID \
    --public-ip $PIP_ID_1
    # 若有多個 IP，請用空格分隔: --public-ips $PIP_ID_1 $PIP_ID_2

az network firewall show \
    --name $FW_NAME \
    --resource-group $RG_NAME \
    --query "{Name:name, Hub:virtualHub.id, ProvisioningState:provisioningState}" \
    --output table