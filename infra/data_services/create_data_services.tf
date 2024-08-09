# variables
variable "pj_name" {}
variable "default_tags" {}
variable "target_rg" {}

# locals for data services
locals {
  ai_search = {
    location = "eastus" # to use multi modal embedding https://learn.microsoft.com/azure/search/cognitive-search-skill-vision-vectorize
  }
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

# create AI search
resource "azurerm_search_service" "srch" {
  name                = "srch-${var.pj_name}-${local.ai_search.location}"
  resource_group_name = var.target_rg.name
  location            = local.ai_search.location
  sku                 = "basic" # set basic when using semantic search
  semantic_search_sku = "free"

  identity {
    type = "SystemAssigned"
  }

  tags = var.default_tags
}

# assign role to AI Search for data access
resource "azurerm_role_assignment" "srch_read_blob" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Contributor" # to read and write
  principal_id         = azurerm_search_service.srch.identity[0].principal_id
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

output "ai_search_api_key" {
  value = azurerm_search_service.srch.primary_key
}
