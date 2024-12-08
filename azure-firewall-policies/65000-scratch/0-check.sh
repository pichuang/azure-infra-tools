#!/bin/bash

source terraform.tfvars

echo "Checking Azure Firewall Policy is existing..."
if az network firewall policy show --name $FW_POLICY_NAME -g $RG_NAME; then
    echo "Azure Firewall Policy exists."
else
    echo "Azure Firewall Policy does not exist."
fi

echo "Checking Azure Firewall Policies tier is Standard or Premium..."
tier=$(az network firewall policy show --name $FW_POLICY_NAME -g $RG_NAME --query "sku.tier" -o tsv)
if [ "$tier" == "Standard" ] || [ "$tier" == "Premium" ]; then
    echo "Azure Firewall Policy tier is $tier."
else
    echo "Azure Firewall Policy tier is not Standard or Premium."
fi

echo "Initializing Terraform..."
terraform init