# variables
variable "pj_name" {}
variable "default_tags" {}
variable "target_rg" {}

# locals for data services
locals {
  openai = {
    location = "eastus2" # to use gpt-4o
    deployments = {
      gpt-4o = {
        model_name = "gpt-4o"
        version    = "2024-05-13"
        capacity   = 1
      }

      text-embedding-ada-002 = {
        model_name = "text-embedding-ada-002"
        version    = "2"
        capacity   = 1
      }
    }
  }

  functions = {
    name_base = "func-${var.pj_name}-"
    location  = var.target_rg.location
  }
}

# create storage account
resource "azurerm_storage_account" "st" {
  name                     = "st${var.pj_name}${var.target_rg.location}"
  resource_group_name      = var.target_rg.name
  location                 = var.target_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.default_tags
}

resource "azurerm_storage_container" "docs" {
  name                  = "docs"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "files" {
  for_each = fileset(path.root, "data_services/docs/*")

  name                   = trim(each.key, "data_services/docs/")
  storage_account_name   = azurerm_storage_account.st.name
  storage_container_name = azurerm_storage_container.docs.name
  type                   = "Block"
  source                 = each.key
}

# create AI services multi-service account
resource "azurerm_cognitive_account" "aisa" {
  name                  = "aisa-${var.pj_name}-${var.target_rg.location}"
  location              = "westeurope" # to use api version, 2024-02-29-preview, to output Markdown style in Document Intelligence API (https://learn.microsoft.com/ja-jp/azure/ai-services/document-intelligence/concept-model-overview?view=doc-intel-4.0.0)
  resource_group_name   = var.target_rg.name
  kind                  = "CognitiveServices"
  custom_subdomain_name = join("", ["aisa-${var.pj_name}-", var.target_rg.location])
  sku_name              = "S0"

  tags = var.default_tags
}

# # create AI search
# resource "azurerm_search_service" "srch" {
#   name                = "srch-${var.pj_name}-${var.target_rg.location}"
#   resource_group_name = var.target_rg.name
#   location            = var.target_rg.location
#   sku                 = "basic" # set basic when using semantic search
#   semantic_search_sku = "free"

#   identity {
#     type = "SystemAssigned"
#   }

#   tags = var.default_tags
# }

# # assign role to AI Search for data access
# resource "azurerm_role_assignment" "srch_read_blob" {
#   scope                = azurerm_storage_account.st.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_search_service.srch.identity[0].principal_id
# }

# create storage account for functions app
resource "azurerm_storage_account" "st_func" {
  name                     = "st${var.pj_name}${var.target_rg.location}func"
  resource_group_name      = var.target_rg.name
  location                 = var.target_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.default_tags
}

# create app service plan for functions app
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.pj_name}-${var.target_rg.location}"
  resource_group_name = var.target_rg.name
  location            = var.target_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = var.default_tags
}

# create functions app
resource "azurerm_linux_function_app" "func" {
  name                       = "func-${var.pj_name}-${var.target_rg.location}"
  resource_group_name        = var.target_rg.name
  location                   = var.target_rg.location
  storage_account_name       = azurerm_storage_account.st_func.name
  storage_account_access_key = azurerm_storage_account.st_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  app_settings = {
    AI_SERVICE_ENDPOINT = azurerm_cognitive_account.aisa.endpoint
    AI_SERVICE_API_KEY  = azurerm_cognitive_account.aisa.primary_access_key
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.appi.connection_string
    application_insights_key               = azurerm_application_insights.appi.instrumentation_key

    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  tags = var.default_tags
}

# create application insights
resource "azurerm_application_insights" "appi" {
  name                = "appi-${var.pj_name}-${var.target_rg.location}"
  location            = var.target_rg.location
  resource_group_name = var.target_rg.name
  application_type    = "other"

  tags = var.default_tags
}

# create OpenAI
resource "azurerm_cognitive_account" "oai" {
  name                  = join("", ["oai-${var.pj_name}-", local.openai.location])
  location              = local.openai.location
  resource_group_name   = var.target_rg.name
  kind                  = "OpenAI"
  custom_subdomain_name = join("", ["oai-${var.pj_name}-", local.openai.location])
  sku_name              = "S0"

  tags = var.default_tags
}

# create model deployments
resource "azurerm_cognitive_deployment" "deployments" {
  for_each = local.openai.deployments

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.oai.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.version
  }

  scale {
    type     = "Standard"
    capacity = each.value.capacity
  }
}

# outputs
output "openai_api_key" {
  value = azurerm_cognitive_account.oai.primary_access_key
}

# output "ai_search_api_key" {
#   value = azurerm_search_service.srch.primary_key
# }
