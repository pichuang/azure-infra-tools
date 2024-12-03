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
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = var.firewall_policy_rule_collection_allow_network_name
    priority = var.firewall_policy_rule_collection_allow_network_priority
    rule = [
      {
        name                  = "Allow Any to Any ICMP"
        source_addresses      = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups      = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null
        destination_addresses = ["*"]
        destination_ports     = ["*"]
        protocols             = ["ICMP"]
      },
      {
        name             = "Allow Any to Azure Firewall DNS"
        source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
        source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

        destination_addresses = ["10.100.2.132"]
        destination_ports     = ["53"]
        protocols             = ["UDP"] # ["Any" "TCP" "UDP" "ICMP"]
      },
    ]
    }
  ]

  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      action   = "Deny"
      name     = var.firewall_policy_rule_collection_deny_application_name
      priority = var.firewall_policy_rule_collection_deny_application_priority
      rule = [
        {
          name             = "Deny All Liability Websites"
          source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
          source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

          # https://github.com/hashicorp/terraform-provider-azurerm/issues/18623
          web_categories = [
            "alcoholandtobacco",
            "childabuseimages",
            "criminalactivity",
            "datingandpersonals",
            "gambling",
            "hacking",
            "hateandintolerance",
            "illegaldrug",
            "illegalsoftware",
            "lingerieandswimsuits",
            "marijuana",
            "nudity",
            "pornographyandsexuallyexplicit",
            "selfharm",
            "sexeducation",
            "tasteless",
            "violence",
            "weapons",
            "peertopeer",
            "games",
            "cults"
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
        }
      ]
    },
    {
      action   = "Allow"
      name     = var.firewall_policy_rule_collection_allow_application_name
      priority = var.firewall_policy_rule_collection_allow_application_priority
      rule = [
        {
          name             = "Allow ifconfig.me"
          source_addresses = length(var.source_addresses) > 0 ? var.source_addresses : null
          source_ip_groups = length(var.source_addresses) == 0 && length(var.source_ip_groups) > 0 ? var.source_ip_groups : null

          destination_fqdns = ["ifconfig.me"]
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
        }
      ]
    }
  ]
}
