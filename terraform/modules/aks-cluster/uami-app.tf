resource "azurerm_user_assigned_identity" "app" {
  name                = "uami-app"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "kv_access_app" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull_app" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: myapp
#   annotations:
#     azure.workload.identity/client-id: <managed-identity-client-id>

#In yaml
# spec:
#   serviceAccountName: myapp

resource "azurerm_federated_identity_credential" "external_secrets" {
  name = "external-secrets"
  # resource_group_name       = var.resource_group_name
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id

  audience = ["api://AzureADTokenExchange"]

  issuer = azurerm_kubernetes_cluster.this.oidc_issuer_url

  subject = "system:serviceaccount:external-secrets:external-secrets"
}