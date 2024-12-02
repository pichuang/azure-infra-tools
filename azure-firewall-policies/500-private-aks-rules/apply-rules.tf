#
# Resources
#

# https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress

module "private_aks_rule_collection_group" {
  source                                                   = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version                                                  = "v0.3.2"
  firewall_policy_rule_collection_group_firewall_policy_id = var.firewall_policy_id
  firewall_policy_rule_collection_group_name               = var.firewall_policy_rule_collection_group_name
  firewall_policy_rule_collection_group_priority           = var.firewall_policy_rule_collection_group_priority

  # Rule Colleciont - Allow DNAT
  # firewall_policy_rule_collection_group_nat_rule_collection = [{
  #   action   = "Allow"
  #   name     = var.firewall_policy_rule_collection_allow_dnat_name
  #   priority = var.firewall_policy_rule_collection_allow_dnat_priority
  #   rule = [
  #   ]
  #   }
  # ]

  # Rule Collection - Allow Network
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = var.firewall_policy_rule_collection_allow_network_name
    priority = var.firewall_policy_rule_collection_allow_network_priority
    rule = [
      {
        # Required for Network Time Protocol (NTP) time synchronization on Linux nodes. This isn't required for nodes provisioned after March 2021.
        name              = "Allow NTP"
        source_addresses  = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups  = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = ["ntp.ubuntu.com"]
        destination_ports = ["123"]
        protocols         = ["UDP"] # ["Any" "TCP" "UDP" "ICMP"]
      },
      {
        # This endpoint is used to send metrics data and logs to Azure Monitor and Log Analytics.
        name                  = "Allow Network Rules for Azure Monitor for containers"
        source_addresses      = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups      = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_addresses = ["AzureMonitor"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }
    ]
    }
  ]

  # Rule Collection - Allow Application
  firewall_policy_rule_collection_group_application_rule_collection = [{
    action   = "Allow"
    name     = var.firewall_policy_rule_collection_allow_application_name
    priority = var.firewall_policy_rule_collection_allow_application_priority
    rule = [
      {
        # Required to access images in Microsoft Container Registry (MCR).
        name = "Allow Microsoft Container Registry"
        #
        # if source_addresses is empty, use source_ip_groups
        #
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_fqdns = [
          "mcr.microsoft.com",
          "*.data.mcr.microsoft.com",
          "mcr-0001.mcr-msedge.net",
          "packages.microsoft.com",
          "acs-mirror.azureedge.net"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        # Required for Kubernetes operations against the Azure API
        name             = "Allow Private AKS to Azure API"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "management.azure.com",
          "login.microsoftonline.com"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        # Required for Microsoft Defender to upload security events to the cloud.
        name             = "Allow Microsoft Defender for Containers"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "*.ods.opinsights.azure.com",
          "*.oms.opinsights.azure.com"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        # Required for CSI Secret Store.
        name              = "Allow CSI Secret Store"
        source_addresses  = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups  = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = ["vault.azure.net"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Application Rules for Azure Monitor for containers"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "dc.services.visualstudio.com",
          "*.ods.opinsights.azure.com",
          "*.oms.opinsights.azure.com",
          "*.monitoring.azure.com",
          "*.ingest.monitor.azure.com",
          "*.handler.control.monitor.azure.com"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Application Rules for Azure Policy"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "data.policy.core.windows.net",
          "store.policy.core.windows.net",
          "dc.services.visualstudio.com",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Application Rules for AKS cost analysis add-on"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "management.azure.com",
          "login.microsoftonline.com",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Application Rules for Cluster extensions"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_fqdns = [
          "arcmktplaceprod.azurecr.io",
          "mcr.microsoft.com",
          "*.data.mcr.microsoft.com",
          "taiwannorth.dp.kubernetesconfiguration.azure.com", # Region
          "*.dp.kubernetesconfiguration.azure.com",
          "arcmktplaceprod.japaneast.data.azurecr.io", # Region
          "*.ingestion.msftcloudes.com",
          "*.microsoftmetrics.com",
          "marketplaceapi.microsoft.com"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
    ]
    }
  ]
}
