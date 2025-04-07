output "aks_cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.k8s.id
}

output "aks_cluster_name" {
  description = "The Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.k8s.name
}

output "aks_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity for the AKS cluster."
  value       = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

output "kube_config_raw" {
  description = "Raw Kubernetes config for the AKS cluster. Use with kubectl."
  value       = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive   = true
}

