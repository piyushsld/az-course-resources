# terraform {
#   required_version = ">= 1.5.0"

#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = ">= 3.102.0"
#     }
#   }
# }

locals {
  identity_ids = var.identity_type == "UserAssigned" && var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : null
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.this.id
  role_definition_name = "Network Contributor"
  principal_id         = var.user_assigned_identity_principal_id
}

resource "azurerm_subnet" "nodes" {
  name                 = var.node_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.node_subnet_prefixes
}

resource "azurerm_subnet" "apiserver" {
  count                = var.api_server_vnet_integration_enabled ? 1 : 0
  name                 = var.api_server_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.api_server_subnet_prefixes

  delegation {
    name = "aks-apiserver-delegation"

    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = azurerm_private_dns_zone.aks.id
  role_based_access_control_enabled = true

  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                         = var.system_pool_name
    vm_size                      = var.system_pool_vm_size
    vnet_subnet_id               = azurerm_subnet.nodes.id
    auto_scaling_enabled         = true
    min_count                    = var.system_pool_min_count
    max_count                    = var.system_pool_max_count
    max_pods                     = var.system_pool_max_pods
    orchestrator_version         = var.kubernetes_version
    only_critical_addons_enabled = true
    type                         = "VirtualMachineScaleSets"
    zones                        = ["1", "2", "3"]
    temporary_name_for_rotation  = "sysrotmp"
  }

  identity {
    type         = var.identity_type
    identity_ids = local.identity_ids
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.rbac_aad_managed ? [1] : []
    content {
      admin_group_object_ids = var.admin_group_object_ids
      azure_rbac_enabled     = true
    }
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = var.load_balancer_sku
    outbound_type     = var.outbound_type
  }

  dynamic "api_server_access_profile" {
    for_each = var.api_server_vnet_integration_enabled ? [1] : []
    content {
      subnet_id                           = azurerm_subnet.apiserver[0].id
      virtual_network_integration_enabled = true
    }
  }

  tags = var.tags
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = var.user_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_pool_vm_size
  vnet_subnet_id        = azurerm_subnet.nodes.id
  mode                  = "User"

  auto_scaling_enabled = true
  min_count            = var.user_pool_min_count
  max_count            = var.user_pool_max_count
  max_pods             = var.user_pool_max_pods

  orchestrator_version = var.kubernetes_version
  zones                = ["1", "2", "3"]
  tags                 = var.tags

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.uksouth.azmk8s.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
}

resource "azurerm_network_security_group" "gh-runner-nsg" {
  name                = "gh-runner-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "gh-runner" {
  name                = "vnet-runner"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/20"]
  tags                = var.tags

  # subnet {
  #   name             = "snet-runner"
  #   address_prefixes = ["10.0.1.0/24"]
  # }

  # subnet {
  #   name             = "AzureBastionSubnet"
  #   address_prefixes = ["10.0.2.0/24"]
  #   security_group   = azurerm_network_security_group.gh-runner-nsg.id
  # }
}

resource "azurerm_subnet" "runner" {
  name                 = "runner-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.gh-runner.name

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion-snet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.gh-runner.name

  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "gh-runner-bastion" {
  name                = "gh-runner-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-snet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

resource "azurerm_public_ip" "nat-pip" {
  name                = "nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "gh-runner-nat" {
  name                = "gh-runner-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat-asscociation" {
  nat_gateway_id       = azurerm_nat_gateway.gh-runner-nat.id
  public_ip_address_id = azurerm_public_ip.nat-pip.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "runner" {
  name                  = "runner-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.gh-runner.id
  registration_enabled  = false
}

resource "azurerm_role_assignment" "aks_private_dns" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = var.user_assigned_identity_principal_id
}

resource "azurerm_virtual_network_peering" "peer-1" {
  name                      = "aks-to-runner"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.gh-runner.name
  remote_virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_virtual_network_peering" "peer-2" {
  name                      = "runner-to-aks"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = azurerm_virtual_network.gh-runner.id
}


resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"

  principal_id = var.user_assigned_identity_principal_id
}

resource "azurerm_role_assignment" "kv_secrets_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "3e380a73-236e-4d4a-85fd-2f9600ba9fc3" # GitHub App Registration's Application (client) ID
}