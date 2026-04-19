resource "azurerm_resource_group" "rg" {
  name     = "rg-terra-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "vnet_terra" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]
}

resource "azurerm_resource_group" "rg_new" {
  for_each = var.resource_groups
  
  name     = "rg-${each.key}-${var.environment}"
  location = each.value
  
  tags = {
    Environment = var.environment
    Purpose     = each.key
  }
}