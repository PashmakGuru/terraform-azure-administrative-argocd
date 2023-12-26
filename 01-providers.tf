terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.79.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.47.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.24.0"
    }
  }
}
