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

# resource "azurerm_private_dns_zone" "redis_private_zone" {
#   name                = "privatelink.redis.cache.windows.net" 
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = local.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "redis_zone_link" {
#   name                  = "${local.resource_prefix}-redis-zone-link"
#   resource_group_name   = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.redis_private_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
#   registration_enabled  = false 
#   tags                  = local.tags
# }

# resource "azurerm_private_endpoint" "redis_pe" {
#   name                = "${module.redis.name}-pe" 
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   subnet_id           = azurerm_subnet.aks_subnet.id 
#   tags                = local.tags

#   private_service_connection {
#     name                           = "${module.redis.name}-psc"
#     private_connection_resource_id = module.redis.id 
#     is_manual_connection           = false
#     subresource_names              = ["redisCache"] 
#   }

#   private_dns_zone_group {
#     name                 = "redis-dns-group" 
#     private_dns_zone_ids = [azurerm_private_dns_zone.redis_private_zone.id]
#   }

#   #
#   depends_on = [
#     module.redis 
#   ]
# }
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

data "local_file" "ssh_pub_key" {
  filename = abspath(pathexpand(var.ssh_public_key_path)) 
}


module "aks" {
  source = "./modules/aks" 
  
  cluster_name        = "${local.resource_prefix}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_subnet_id      = azurerm_subnet.aks_subnet.id 
  ssh_public_key      = data.local_file.ssh_pub_key.content 
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

# module "redis" {
#   source = "./modules/redis"
  
#   name                = "${local.resource_prefix}-redis"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   capacity            = 1
#   family              = "C"
#   sku                 = "Basic"
#   tags                = local.tags
# }


resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = module.aks.aks_principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true
}