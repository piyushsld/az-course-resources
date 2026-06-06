output "aks_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "private_fqdn" {
  value = azurerm_kubernetes_cluster.this.private_fqdn
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "node_subnet_id" {
  value = azurerm_subnet.nodes.id
}

output "api_server_subnet_id" {
  value = try(azurerm_subnet.apiserver[0].id, null)
}

output "cloud_init_debug" {
  value = local.cloud_init
}

output "key_value_id" {
  value = azurerm_key_vault.this.id
}