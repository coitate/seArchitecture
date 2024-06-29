# data sources
data "azurerm_resource_group" "my_rg" {
  name = local.rg_name
}

data "azurerm_client_config" "current" {}

# locals in common
locals {
  rg_name = "rg-ep7-sandbox-oitate"
  pj_name = "searchi" # short for seArchitecture to avoid storage account name length limit
  default_tags = {
    Owner       = "chihiro.oitate@sun-asterisk.com"
    Description = "for seArchitecture project"
    Note        = "This resource is created by Terraform"
  }
}

# modules
module "data_services" {
  source       = "./data_services"
  pj_name      = local.pj_name
  default_tags = local.default_tags
  target_rg    = data.azurerm_resource_group.my_rg
}

# outputs
output "openai_api_key" {
  value     = module.data_services.openai_api_key
  sensitive = true
}

output "ai_search_api_key" {
  value     = module.data_services.ai_search_api_key
  sensitive = true
}
