variable "resource_group_name" {
  type        = string
  description = "Resource group where AKS and networking will be created."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "uksouth"
}

variable "cluster_name" {
  type        = string
  description = "AKS cluster name."
}

variable "dns_prefix" {
  type        = string
  description = "AKS DNS prefix."
}

variable "kubernetes_version" {
  type        = string
  description = "Optional AKS version."
  default     = null
}

variable "sku_tier" {
  type        = string
  description = "AKS pricing tier."
  default     = "Standard"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster."
  default     = true
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID, or null for system-managed private DNS."
  default     = null
}

variable "identity_type" {
  type        = string
  description = "SystemAssigned or UserAssigned."
  default     = "SystemAssigned"
}

variable "user_assigned_identity_id" {
  type        = string
  description = "User assigned identity ID when identity_type is UserAssigned."
  default     = null
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name."
  default     = "vnet-aks"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet CIDR."
  default     = ["10.50.0.0/16"]
}

variable "node_subnet_name" {
  type        = string
  description = "AKS node subnet name."
  default     = "snet-aks-nodes"
}

variable "node_subnet_prefixes" {
  type        = list(string)
  description = "AKS node subnet CIDR."
  default     = ["10.50.1.0/24"]
}

variable "create_api_server_subnet" {
  type        = bool
  description = "Create API server subnet for API server VNet integration."
  default     = true
}

variable "api_server_subnet_name" {
  type        = string
  description = "API server subnet name."
  default     = "snet-aks-apiserver"
}

variable "api_server_subnet_prefixes" {
  type        = list(string)
  description = "API server subnet CIDR."
  default     = ["10.50.2.0/28"]
}

variable "system_pool_name" {
  type    = string
  default = "system"
}

variable "system_pool_vm_size" {
  type    = string
  default = "Standard_D2ps_v6"
}

variable "system_pool_min_count" {
  type    = number
  default = 2
}

variable "system_pool_max_count" {
  type    = number
  default = 5
}

variable "system_pool_max_pods" {
  type    = number
  default = 30
}

variable "user_pool_name" {
  type    = string
  default = "userpool"
}

variable "user_pool_vm_size" {
  type    = string
  default = "Standard_D2ps_v6"
}

variable "user_pool_min_count" {
  type    = number
  default = 2
}

variable "user_pool_max_count" {
  type    = number
  default = 5
}

variable "user_pool_max_pods" {
  type    = number
  default = 30
}

variable "node_os_upgrade_channel" {
  type    = string
  default = "NodeImage"
}

variable "automatic_upgrade_channel" {
  type    = string
  default = "patch"
}

variable "network_plugin" {
  type    = string
  default = "azure"
}

variable "network_policy" {
  type    = string
  default = "azure"
}

variable "load_balancer_sku" {
  type    = string
  default = "standard"
}

variable "outbound_type" {
  type    = string
  default = "loadBalancer"
}

variable "rbac_aad_managed" {
  type    = bool
  default = true
}

variable "admin_group_object_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "api_server_vnet_integration_enabled" {
  description = "Enable API server VNet integration."
  type        = bool
  default     = false
}

variable "user_assigned_identity_principal_id" {
  type        = string
  description = "User assigned identity principal ID for role assignment when identity_type is UserAssigned."
  default     = null
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access."
  sensitive   = true
}

variable "gh_runner_url" {
  type        = string
  description = "GitHub Actions runner URL, e.g."
}

variable "gh_runner_token" {
  type        = string
  description = "GitHub Actions runner token."
  sensitive   = true
}

variable "pvt_ep_subnet_space" {
  type        = list(string)
  description = "Private endpoint subnet CIDR for private cluster API server."
  default     = ["10.50.3.0/24"]
}