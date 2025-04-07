variable "name" {
  type        = string
  description = "The name of the Redis instance."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Redis instance."
}

variable "location" {
  type        = string
  description = "The Azure region where the Redis instance should be created."
}

variable "capacity" {
  type        = number
  description = "The size of the Redis cache to deploy (0, 1, 2, 3, 4, 5, 6)."
  default     = 1
}

variable "family" {
  type        = string
  description = "The SKU family/pricing group to use (C or P)."
  default     = "C"
}

variable "sku" {
  type        = string
  description = "The SKU of Redis to use (Basic, Standard, Premium)."
  default     = "Standard"
}

variable "enable_non_ssl_port" {
  type        = bool
  description = "Enable the non-SSL port (6379)."
  default     = false
}

variable "maxmemory_policy" {
  type        = string
  description = "The Redis maxmemory policy to use."
  default     = "volatile-lru"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default     = {}
}