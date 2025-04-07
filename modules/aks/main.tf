
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns" 
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name            = "default" 
    vm_size         = var.vm_size
    node_count      = var.node_count
    vnet_subnet_id  = var.vnet_subnet_id 
    
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_public_key 
    }
  }

  network_profile {
    network_plugin    = "kubenet" 
    load_balancer_sku = "standard"
  }

  

  

}

