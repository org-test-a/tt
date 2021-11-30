data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = var.aks.name
  dns_prefix          = var.aks.dns_prefix
  kubernetes_version  = var.aks.kubernetes_version
  tags                = var.aks.type

  default_node_pool {
    name                = var.aks_default_node_pool.name
    node_count          = var.aks_default_node_pool.node_count
    vm_size             = var.aks_default_node_pool.vm_size
    availability_zones  = var.aks_default_node_pool.availability_zones
    enable_auto_scaling = var.aks_default_node_pool.enable_auto_scaling
    max_pods            = var.aks_default_node_pool.max_podsx
    max_count           = var.aks_default_node_pool.max_count
    min_count           = var.aks_default_node_pool.min_count
  }

  network_profile {
    network_policy = var.aks_network_policyaks_network_policy
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    prevent_destroy = true
  }
}
