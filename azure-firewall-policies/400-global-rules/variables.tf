terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

#
# Variables
#

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "firewall_policy_id" {
  description = "The ID of the firewall policy."
  type        = string
}

variable "enable_telemetry" {
  description = "Enable telemetry for the module."
  type        = bool
  default     = false
}

variable "firewall_policy_rule_collection_group_name" {
  description = "The name of the firewall policy."
  type        = string
  default     = "rcg-global-rules"
}

variable "firewall_policy_rule_collection_group_priority" {
  description = "The priority of the firewall policy rule collection group."
  type        = number
  default     = 400
}

variable "firewall_policy_rule_collection_allow_dnat_name" {
  description = "The name of the firewall policy rule collection."
  type        = string
  default     = "allow-dnat-rules"
}

variable "firewall_policy_rule_collection_allow_dnat_priority" {
  description = "The priority of the firewall policy rule collection."
  type        = number
  default     = 200
}

variable "firewall_policy_rule_collection_allow_network_name" {
  description = "The name of the firewall policy rule collection."
  type        = string
  default     = "allow-network-rules"
}

variable "firewall_policy_rule_collection_allow_network_priority" {
  description = "The priority of the firewall policy rule collection."
  type        = number
  default     = 400
}

variable "firewall_policy_rule_collection_deny_application_name" {
  description = "The name of the firewall policy rule collection."
  type        = string
  default     = "deny-application-rules"
}

variable "firewall_policy_rule_collection_deny_application_priority" {
  description = "The priority of the firewall policy rule collection."
  type        = number
  default     = 500
}

variable "firewall_policy_rule_collection_allow_application_name" {
  description = "The name of the firewall policy rule collection."
  type        = string
  default     = "allow-application-rules"
}

variable "firewall_policy_rule_collection_allow_application_priority" {
  description = "The priority of the firewall policy rule collection."
  type        = number
  default     = 600
}

variable "source_addresses" {
  description = "The source addresses of the firewall policy rule collection."
  type        = list(string)
  default     = []
}

variable "source_ip_groups" {
  description = "List of source IP groups"
  type        = list(string)
  default     = []
}
