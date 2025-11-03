#!/bin/bash

echo
echo "Remove the problematic resource from the state file..."
echo
terraform state rm 'azurerm_resource_group.practice_rg'

sleep 5

echo
echo "Import the existing resource into the state file with the correct ID..."
echo

terraform import azurerm_resource_group.practice_rg $(az group show -n rg-practice-terraform-state --query id -o tsv)

sleep 5

echo
echo "Verify the import by running terraform plan..."
echo

terraform plan

echo
echo "Should show no changes"
echo