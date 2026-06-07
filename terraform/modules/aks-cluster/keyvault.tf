data "azurerm_client_config" "current" {}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault" "this" {
  name                = "azurelddemouksouth01"
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  rbac_authorization_enabled = true

  public_network_access_enabled = false

  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name

  virtual_network_id   = azurerm_virtual_network.this.id
  registration_enabled = false
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pep-kv"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "kv-dns-zone-group"

    private_dns_zone_ids = [
      azurerm_private_dns_zone.kv.id
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv-runner" {
  name                  = "kv-runner-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name

  virtual_network_id   = azurerm_virtual_network.gh-runner.id
  registration_enabled = false
}