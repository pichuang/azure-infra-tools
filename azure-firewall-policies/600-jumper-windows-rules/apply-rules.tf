#
# Resources
#

module "global_rule_collection_group" {
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
  # firewall_policy_rule_collection_group_network_rule_collection = [{
  #   action   = "Allow"
  #   name     = var.firewall_policy_rule_collection_allow_network_name
  #   priority = var.firewall_policy_rule_collection_allow_network_priority
  #   rule = [
  #     {
  #       name              = "Allow Any to Any ICMP"
  #       source_addresses  = ["*"]
  #       destination_addresses = ["*"]
  #       destination_ports     = ["*"]
  #       protocols             = ["ICMP"]
  #     },
  #   ]
  #   }
  # ]

  # Rule Collection - Allow Application
  firewall_policy_rule_collection_group_application_rule_collection = [{
    action   = "Allow"
    name     = var.firewall_policy_rule_collection_allow_application_name
    priority = var.firewall_policy_rule_collection_allow_application_priority
    rule = [
      {
        name             = "Allow Windows Update"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        # https://learn.microsoft.com/en-us/azure/firewall/fqdn-tags
        destination_fqdn_tags = [
          "WindowsUpdate",
          "WindowsDiagnostics",
          "MicrosoftActiveProtectionService"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Kubernetes Tools"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_fqdns = [
          # Install kubectl
          "dl.k8s.io",
          "*.dl.k8s.io",
          "*.pki.goog",
          # Install Lens
          "k8slens.dev",
          "*.k8slens.dev",
        ]
        protocols = [
          {
            port = 80
            type = "Http"
          },
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow GitHub Services"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_fqdns = [
          # Its enough to allow download k9s from github.com
          "github.com",
          "*.githubusercontent.com"
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Azure Active Directory"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        # https://learn.microsoft.com/zh-tw/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud#azure-portal-urls-for-proxy-bypass
        destination_fqdns = [
          "login.microsoftonline.com",
          "*.aadcdn.msftauth.net",
          "*.aadcdn.msftauthimages.net",
          "*.aadcdn.msauthimages.net",
          "*.logincdn.msftauth.net",
          "login.live.com",
          "*.msauth.net",
          "*.aadcdn.microsoftonline-p.com",
          "*.microsoftonline-p.com",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Azure Portal"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        # https://learn.microsoft.com/zh-tw/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud#azure-portal-urls-for-proxy-bypass
        destination_fqdns = [
          "portal.azure.com",
          "hosting.portal.azure.net",
          "hosting-ms.portal.azure.net",
          "hosting.partners.azure.net",
          "reactblade.portal.azure.net",
          "ms.hosting.portal.azure.net",
          "*.hosting.portal.azure.net",
          "management.azure.com",
          "*.ext.azure.com",
          "*.graph.windows.net",
          "*.graph.microsoft.com",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Microsoft Docs"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        # https://learn.microsoft.com/zh-tw/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud#azure-portal-urls-for-proxy-bypass
        destination_fqdns = [
          "aka.ms",
          "*.aka.ms",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Private Azure Managed Grafana"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_fqdns = [
          # Need to Allow Azure Active Directory
          "*.grafana.azure.com",
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name             = "Allow Azure Cloud Shell"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_fqdns = [
          # Cloud Shell
          "ux.console.azure.com",
          "*.servicebus.windows.net",
          # Serial Console
          "compute.hosting.portal.azure.net",
          "portal.serialconsole.azure.com",
          # TODO
          # Boot diagnostics / Log Analytics
        ]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      }
    ]
    }
  ]
}
