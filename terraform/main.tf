resource "azurerm_resource_group" "rg" {
  name     = "rg-demo-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]
}
