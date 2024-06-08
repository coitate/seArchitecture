terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.80.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-ep7-sandbox-oitate"
    storage_account_name = "sttfstateoitate3"
    container_name       = "searchitecture"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}
