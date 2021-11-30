terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.86.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

module "aks" {
  source = "./modules/aks"
}
