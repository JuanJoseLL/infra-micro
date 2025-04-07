variable "name" {
  type        = string
  description = "The name of the container registry. Only alphanumeric characters allowed."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the container registry."
}

variable "location" {
  type        = string
  description = "The Azure region where the container registry should exist."
}

variable "sku" {
  type        = string
  description = "The SKU name of the container registry. Possible values are Basic, Standard and Premium."
  default     = "Standard"
}

variable "admin_enabled" {
  type        = bool
  description = "Specifies whether the admin user is enabled."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default     = {}
}