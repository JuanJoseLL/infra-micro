variable "resource_group_location" {
  type        = string
  default     = "East US"
  description = "Location for all resources."
}

variable "prefix" {
  type        = string
  default     = "micsvc-ws"
  description = "Prefix for naming resources."
}

variable "common_tags" {
  type = map(string)
  default = {
    environment = "workshop"
    project     = "MicroserviceApp"
  }
  description = "Common tags to apply to all resources."
}

variable "aks_node_count" {
  type        = number
  description = "The initial quantity of nodes for the AKS node pool."
  default     = 1
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file to use for AKS nodes (e.g., ~/.ssh/id_rsa.pub)."
  default     = "~/.ssh/id_rsa.pub" 
}