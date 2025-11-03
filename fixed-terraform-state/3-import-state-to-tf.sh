#!/bin/bash


az group show -n rg-practice-terraform-state --query id -o tsv

terraform import azurerm_resource_group.practice_rg $(az group show -n rg-practice-terraform-state --query id -o tsv)

echo
echo "The import should be failed because the resource already exists in the state."
echo