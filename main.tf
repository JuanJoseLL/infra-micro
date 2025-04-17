resource "random_pet" "suffix" {
  length = 1
}
locals {
  resource_prefix = "${var.prefix}-${random_pet.suffix.id}" 
  tags            = merge(var.common_tags, { creator = "terraform", prefix = local.resource_prefix })
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_prefix}-rg"
  location = var.resource_group_location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "redis_private_zone" {
  name                = "privatelink.redis.cache.windows.net" 
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_zone_link" {
  name                  = "${local.resource_prefix}-redis-zone-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.redis_private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false 
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "redis_pe" {
  name                = "${module.redis.name}-pe" 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.aks_subnet.id 
  tags                = local.tags

  private_service_connection {
    name                           = "${module.redis.name}-psc"
    private_connection_resource_id = module.redis.id 
    is_manual_connection           = false
    subresource_names              = ["redisCache"] 
  }

  private_dns_zone_group {
    name                 = "redis-dns-group" 
    private_dns_zone_ids = [azurerm_private_dns_zone.redis_private_zone.id]
  }

  #
  depends_on = [
    module.redis 
  ]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet" 
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry"]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${local.resource_prefix}-aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

module "aks" {
  source = "./modules/aks" 
  
  cluster_name        = "${local.resource_prefix}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_subnet_id      = azurerm_subnet.aks_subnet.id 
  ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRk10lbQMiG6cs97m3gQuDoMB2CYKNQMgMj03kWtnH8OriMdik4uHJvp+FYKWFfD3bQV6QMb0/5i/kmFMjfI9Ax9wat/Uo+TvVtSfs4WWuTOXPCSXXycAcgrefQSo0xGuhWh1icDSmHiJOqJhf+eiSe6HGVVhLisX2n8YaOskv/UFPZyTMdB754CsSgnbNZbLPXRXb0q5EsBmRzDGQ2+5w7LtLY9SMsl6qRORJdJJ8uSDyu1qr4/JTkJCmcUSvrdLq3NTW/OsDWIRAiHgtcexTZ2TMrUOtTkl5Bz8HtxhxlRDoJDno2HmCjFVZ8uW/ItLmrzwE2fwRg6UukpnXNo7NFBDD4RbCPuVuQYyA19xmPCz9rYiKOmGHXt5yKwIa69Z7WKfiuC+bvgmEhq+m7widnkJmWpmmN2a9cn3phyNDJyE5xxLecEm6TtR+B4FSufMN4mKeESbQBdtKrlPcQMzNlnBYFO9iLpn6k7K9E5f2YAQZVcR35/V3Ply2gY5cHp5TIDR8eOMsOAGwSOv2B3/f3sUkvPfCuj+Qc6taNhWgUZ3/DMiBz1/2c9cKykqe2ONqgFwtt8bDHp9Gr4gsX0nZ2EZHQU/Uhp0bVaUyzaLc7s+XtwWeIpd10BhHK8DCQ235fANwHMSZJWzQWCwjglh9J27dUiGGgnmeKxvW8BvfBQ== juanjose@MacBook-Air-JuanJ.local"
  node_count         = var.aks_node_count
  vm_size            = "Standard_D2_v2" 
  tags               = local.tags
}

module "acr" {
  source = "./modules/acr"
  
  name                = "${replace(local.resource_prefix, "-", "")}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
  tags                = local.tags
}

module "redis" {
  source = "./modules/redis"
  
  name                = "${local.resource_prefix}-redis"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  capacity            = 1
  family              = "C"
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = module.aks.aks_principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true
}