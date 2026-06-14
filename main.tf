terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.77.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
  subscription_id = "9441bbd5-0154-42cc-a0bb-d6c94e0f0b3b"
}

resource "azurerm_resource_group" "rg" {
    name = "rg-develop"
    location            = "East US 2"
  
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-dev-robo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksdev"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "standard_d2ads_v7"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
}

# commit-marker-2: verify network_policy set for AKS
