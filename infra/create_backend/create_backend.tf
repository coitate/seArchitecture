# # variables
# variable "pj_name" {}
# variable "default_tags" {}
# variable "target_rg" {}

# # locals for backend
# locals {
#   container_apps = {
#     name_base = "ca-${var.pj_name}-"
#   }
# }

# resource "azurerm_container_app_environment" "cae" {
#   name                = join("", [local.container_apps.name_base, "cae"])
#   resource_group_name = var.target_rg.name
#   location            = var.target_rg.location

#   tags = var.default_tags
# }

# resource "azurerm_container_app" "ca" {
#   name                         = local.container_apps.name_base
#   container_app_environment_id = azurerm_container_app_environment.cae.id
#   resource_group_name          = var.target_rg.name
#   revision_mode                = "Single"

#   template {
#     container {
#       cpu = 1.0
#       env {

#       }
#     }
#   }

#   tags = var.default_tags
# }

# resource "azurerm_container_app" "example" {
#   name                         = "example-app"
#   container_app_environment_id = azurerm_container_app_environment.example.id
#   resource_group_name          = azurerm_resource_group.example.name
#   revision_mode                = "Single"

#   template {
#     container {
#       name   = "examplecontainerapp"
#       image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
#       cpu    = 0.25
#       memory = "0.5Gi"
#     }
#   }
# }
