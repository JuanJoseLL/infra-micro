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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRk10lbQMiG6cs97m3gQuDoMB2CYKNQMgMj03kWtnH8OriMdik4uHJvp+FYKWFfD3bQV6QMb0/5i/kmFMjfI9Ax9wat/Uo+TvVtSfs4WWuTOXPCSXXycAcgrefQSo0xGuhWh1icDSmHiJOqJhf+eiSe6HGVVhLisX2n8YaOskv/UFPZyTMdB754CsSgnbNZbLPXRXb0q5EsBmRzDGQ2+5w7LtLY9SMsl6qRORJdJJ8uSDyu1qr4/JTkJCmcUSvrdLq3NTW/OsDWIRAiHgtcexTZ2TMrUOtTkl5Bz8HtxhxlRDoJDno2HmCjFVZ8uW/ItLmrzwE2fwRg6UukpnXNo7NFBDD4RbCPuVuQYyA19xmPCz9rYiKOmGHXt5yKwIa69Z7WKfiuC+bvgmEhq+m7widnkJmWpmmN2a9cn3phyNDJyE5xxLecEm6TtR+B4FSufMN4mKeESbQBdtKrlPcQMzNlnBYFO9iLpn6k7K9E5f2YAQZVcR35/V3Ply2gY5cHp5TIDR8eOMsOAGwSOv2B3/f3sUkvPfCuj+Qc6taNhWgUZ3/DMiBz1/2c9cKykqe2ONqgFwtt8bDHp9Gr4gsX0nZ2EZHQU/Uhp0bVaUyzaLc7s+XtwWeIpd10BhHK8DCQ235fANwHMSZJWzQWCwjglh9J27dUiGGgnmeKxvW8BvfBQ== juanjose@MacBook-Air-JuanJ.local" 
}