resource "azurerm_resource_group" "rg2" {
  name     = "tf-demo"
  location = "Canada Central"
}

resource "azurerm_user_assigned_identity" "rg1-id" {
  location            = "Canada Central"
  name                = "tf-id-demo"
  resource_group_name = azurerm_resource_group.rg2.name
}