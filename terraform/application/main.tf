resource "azurerm_resource_group" "rg2"{
  name     = "tf-demo"
  location = "Central India"
}
resource "azurerm_user_assigned_identity" "rg2-id" {
  location            = "Central India"
  name                = "tf-id-demo"
  resource_group_name = azurerm_resource_group.rg2.name
  # depends_on = [ azurerm_resource_group.rg2]
}