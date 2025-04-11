output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  description = "AKS Cluster Name"
  value       = module.aks.aks_cluster_name
}

output "aks_kube_config_raw" {
  description = "Raw Kubernetes config for the AKS cluster."
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "vnet_name" {
   value = azurerm_virtual_network.vnet.name
}

# Add these new outputs
output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry."
  value       = module.acr.login_server
}

output "acr_admin_username" {
  description = "The admin username for accessing the Azure Container Registry."
  value       = module.acr.admin_username
}

# output "redis_hostname" {
#   description = "The hostname of the Redis instance."
#   value       = module.redis.hostname
# }

