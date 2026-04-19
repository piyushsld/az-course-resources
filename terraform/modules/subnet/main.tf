resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}-${var.environment}"
  resource_group_name  = var.rgname
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefix]

  dynamic "delegation" {
    for_each = var.subnet_delegation == null ? [] : [var.subnet_delegation]

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service
        actions = sort(delegation.value.actions)
      }
    }
  }
}