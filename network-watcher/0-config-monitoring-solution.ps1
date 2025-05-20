$subscriptionIdorName = "subscription-vendor"
$location = "southeastasia"
$resourceGroup = "rg-networkwatcher-aruba-sea"
$workspaceName = "log-networkwatcher-aruba-sea"

Select-AzSubscription -SubscriptionId $subscriptionIdorName

$subscription = Get-AzSubscription -SubscriptionName $subscriptionIdorName
if ($subscription) {
    $subscriptionIdorName = $subscription.Id
}
# Check if the subscription is valid
if (-not $subscriptionIdorName) {
    Write-Host "Subscription not found"
    exit
}

# Create resource group if not existing
$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
}
# Create Log Analytics workspace if not existing
$workspace = Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
if (-not $workspace) {
    New-AzOperationalInsightsWorkspace -Name $workspaceName -Location $location -Sku "PerGB2018" -ResourceGroupName $resourceGroup
}

$solution = @{
    Location          = $location
    Properties        = @{
        workspaceResourceId = "/subscriptions/$($subscription)/resourcegroups/$($resourceGroup)/providers/Microsoft.OperationalInsights/workspaces/$($workspaceName)"
    }
    Plan              = @{
        Name          = "NetworkMonitoring($($workspaceName))"
        Publisher     = "Microsoft"
        Product       = "OMSGallery/NetworkMonitoring"
        PromotionCode = ""
    }
    ResourceName      = "NetworkMonitoring($($workspaceName))"
    ResourceType      = "Microsoft.OperationsManagement/solutions"
    ResourceGroupName = $resourceGroup
}

New-AzResource @solution -Force
