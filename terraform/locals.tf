locals {
  delegation_defaults = {
    "Microsoft.ContainerInstance/containerGroups" = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
    ]
    "Microsoft.Web/serverFarms" = [
      "Microsoft.Network/virtualNetworks/subnets/action"
    ]
    "Microsoft.Databricks/workspaces" = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
    ]
  }

  subnet_delegation = var.delegation_enabled && var.delegation_service_name != null ? {
    name    = "delegation"
    service = var.delegation_service_name
    actions = lookup(local.delegation_defaults, var.delegation_service_name, [])
  } : null
}
