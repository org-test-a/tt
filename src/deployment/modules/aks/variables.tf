variable "subscription_id" {
  description = "Azure suscription id."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant id."
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name."
  type        = string

  validation {
    condition = alltrue([
      length(var.resource_group_name) > 5,
      length(var.resource_group_name) <= 50
    ])
    error_message = "The resource group name must be 5-50 characters in length."
  }
}

variable "aks_network_policy" {
  description = "Sets up network policy to be used with Azure CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are 'calico' and 'azure'."
  type        = string
  default     = "calico"

  validation {
    condition = anytrue([
      var.aks_network_policy == "calico",
      var.aks_network_policy == "azure"
    ])
    error_message = "The network policy currently supported values are 'calico' or 'azure'."
  }
}

variable "aks" {
  type = object({
    name               = string
    dns_prefix         = string
    kubernetes_version = string
    type               = map(string)
  })

  validation {
    condition = alltrue([
      length(var.aks.name) > 1,
      length(var.aks.name) <= 63,
      can(regex("^[a-zA-Z](\\w*)[a-zA-Z]$", var.aks.name))
    ])
    error_message = "The cluster name must be 1-63 characters in length."
  }

  default = {
    name               = null
    dns_prefix         = ""
    kubernetes_version = "1.20.9"
    type               = {}
  }
}

variable "aks_default_node_pool" {
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    availability_zones  = list(string)
    enable_auto_scaling = bool
    max_pods            = number
    min_count           = number
    max_count           = number
  })

  validation {
    condition = can([
      for zone in var.aks_default_node_pool.availability_zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "Must be a valid availability zones."
  }
  validation {
    condition     = var.aks_default_node_pool.max_pods <= 250
    error_message = "The maximum number of pods is 250."
  }
  validation {
    condition     = var.aks_default_node_pool.min_count >= 1
    error_message = "The agents min count greater or equal than 1."
  }
  validation {
    condition     = var.aks_default_node_pool.node_count <= 1
    error_message = "The node count greater or equal than 1."
  }
  validation {
    condition = alltrue([
      var.aks_default_node_pool.max_count > 1,
      var.aks_default_node_pool.max_count <= 100
    ])
    error_message = "The agents max count must be 1-100."
  }

  default = {
    name                = null
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    max_count           = 100
    max_pods            = 250
    min_count           = 1
    node_count          = 3
    vm_size             = "Standard_DS2_v2"
  }
}
