
subscription_id = "0a4374d1-bc72-46f6-a4ae-a9d8401369db"

# Firewall Policy
firewall_policy_id = "/subscriptions/0a4374d1-bc72-46f6-a4ae-a9d8401369db/resourceGroups/rg-hub-er-taiwannorth/providers/Microsoft.Network/firewallPolicies/afwp-hub-twn"

#
# Rule Collection Group
#
firewall_policy_rule_collection_group_name = "rcg-global-rules"
# The number must be unique across all rule collection groups in the policy.
firewall_policy_rule_collection_group_priority = 400

# Rule Collection - Allow DNAT
firewall_policy_rule_collection_allow_dnat_name     = "allow-dnat-rules"
firewall_policy_rule_collection_allow_dnat_priority = 200

# Rule Collection - Allow Network
firewall_policy_rule_collection_allow_network_name     = "allow-network-rules"
firewall_policy_rule_collection_allow_network_priority = 400

# Rule Collection - Deny Application
firewall_policy_rule_collection_deny_application_name     = "deny-application-rules"
firewall_policy_rule_collection_deny_application_priority = 500

# Rule Collection - Allow Application
firewall_policy_rule_collection_allow_application_name     = "allow-application-rules"
firewall_policy_rule_collection_allow_application_priority = 600


# Use one of the following variables
source_addresses = []
source_ip_groups = [
  "/subscriptions/0a4374d1-bc72-46f6-a4ae-a9d8401369db/resourceGroups/rg-hub-er-taiwannorth/providers/Microsoft.Network/ipGroups/ipg-hub-twn",
  "/subscriptions/0a4374d1-bc72-46f6-a4ae-a9d8401369db/resourceGroups/rg-hub-er-taiwannorth/providers/Microsoft.Network/ipGroups/ipg-zone1-twn"
]