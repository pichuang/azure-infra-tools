#
# This script transfers a domain out of Azure DNS to another registrar.
# It uses the Azure CLI and Az PowerShell module to perform the transfer.
# Prerequisites:
# - http://shell.azure.com or Azure CLI installed
# - Azure subscription and resource group created
# - Domain registered with Azure DNS
# Usage:
# 1. Set the variables for your Azure subscription, resource group, and domain name.
# 2. Run the script in PowerShell.
# Example usage:
# Set the variables for your Azure subscription, resource group, and domain name.
# Replace the values with your own
#

SUBSCRIPTION_ID=""
RESOURCE_GROUP_NAME=""
DOMAIN_NAME=""
FILE_NAME="azure-public-dns-transfer-out-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Set the Azure subscription context
Set-AzContext -SubscriptionId $SUBSCRIPTION_ID -ErrorAction Stop

# Execute the transfer out command
Invoke-AzRestMethod -Path "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.DomainRegistration/domains/$DOMAIN_NAME/transferout?api-version=2021-02-01" -Method PUT | Out-File -FilePath $FILE_NAME -Append

# Show output from file name
Get-Content -Path $FILE_NAME | Write-Output
