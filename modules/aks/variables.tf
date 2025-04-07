variable "cluster_name" {
  type        = string
  description = "The name for the AKS cluster."
}

variable "location" {
  type        = string
  description = "The Azure region where the AKS cluster will be created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the existing Resource Group to deploy AKS into."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the default node pool."
  default     = 5
}

variable "vm_size" {
  type        = string
  description = "The VM size for the AKS nodes in the default node pool."
  default     = "Standard_DS2_v2"
}

variable "vnet_subnet_id" {
  type        = string
  description = "The ID of the Subnet where the AKS nodes should be deployed."
}

variable "admin_username" {
  type        = string
  description = "The admin username for the nodes."
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key data used to access the AKS nodes."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to assign to the AKS cluster resource."
}
