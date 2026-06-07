resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pep-acr"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "acr-dns-zone-group"

    private_dns_zone_ids = [
      azurerm_private_dns_zone.acr.id
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name

  virtual_network_id   = azurerm_virtual_network.this.id
  registration_enabled = false
}

resource "azurerm_container_registry" "acr" {
  name                = "azurelddemo"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku           = "Premium"
  admin_enabled = false

  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = var.pvt_ep_subnet_space
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_runner" {
  name                  = "acr-runner-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name

  virtual_network_id   = azurerm_virtual_network.gh-runner.id
  registration_enabled = false
}

