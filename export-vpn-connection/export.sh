#!/bin/bash

SUBSCRIPTION_ID="subscription-sandbox-any-projects"
RESOURCE_GROUP_NAME="rg-tf-hub-twn"
VPN_GATEWAY_NAME="vpn-tf-twn"
EXPORT_FILE="vpn-connections.json"

# Show
az network vpn-connection list \
    --subscription "$SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --vnet-gateway "$VPN_GATEWAY_NAME" \
    --output json > "$EXPORT_FILE"
