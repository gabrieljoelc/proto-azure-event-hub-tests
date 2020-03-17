terraform {
  required_version = ">= 0.12.4"
}

provider "azurerm" {
  version = ">= 2.0.0"
  features {}
}

# ###############
# required values
# ###############

variable "name" {
  description = "The name of the web app"
}

variable "rg" {
  description = "The name of the resource group in which the resources will be created."
}

# ###############
# optional values
# ###############

variable "location" {
  description = "Region where the resources are created."
  default     = "westus"
}

variable "plan_settings" {
  description = "Definition of the dedicated plan to use"

  default = {
    kind     = "Windows" # Linux or Windows
    size     = "S1"
    capacity = 1
    tier     = "Standard"
    reserved     = false
  }
}

variable "service_plan_name" {
  description = "The name of the App Service Plan, default = $web_app_name"
  default     = ""
}

variable "eh_namespace" {
  description = "Event Hub namespace to create a test hub in"
}

variable "hub_name" {
  description = "Event Hub hub to send test messages"
  default     = "test-hub"
}

variable "partition_count" {
  description = "Number of partitions to create the hub with"
  default     = 32
}

data "azurerm_resource_group" "webjob" {
  name     = var.rg
}

data "azurerm_eventhub_namespace" "webjob" {
  name = var.eh_namespace
  resource_group_name = var.rg
}

resource "azurerm_eventhub" "webjob" {
  name                = var.hub_name
  namespace_name      = var.eh_namespace
  resource_group_name = var.rg
  partition_count     = var.partition_count
  message_retention   = 1
}

# database for storing test runs
resource "azurerm_sql_server" "webjob" {
  name                         = "${var.name}-db-server"
  resource_group_name          = data.azurerm_resource_group.webjob.name
  location                     = "West US"
  version                      = "12.0"
  administrator_login          = "myamazinglogin"
  administrator_login_password = "2QhypLZ^%1"
}

resource "azurerm_sql_database" "webjob" {
  name                = "${var.name}-db-server"
  resource_group_name = data.azurerm_resource_group.webjob.name
  location            = "West US"
  server_name         = azurerm_sql_server.webjob.name
}

# storage account for EH management
resource "azurerm_storage_account" "webjob" {
  name                = "${var.name}storage"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.webjob.name
  account_kind        = "Storage"
  account_tier        = "Standard"
  account_replication_type          = "LRS"
  enable_https_traffic_only         = true
}

resource "azurerm_application_insights" "webjob" {
  name = "${var.name}-ai"
  location = "West US 2"
  resource_group_name = var.rg
  application_type = "web"
}

resource "azurerm_app_service_plan" "webjob" {
  name                = var.service_plan_name == "" ? replace(var.name, "/[^a-z0-9]/", "") : var.service_plan_name
  location            = data.azurerm_resource_group.webjob.location
  resource_group_name = data.azurerm_resource_group.webjob.name
  
  kind                = var.plan_settings["kind"]

  reserved            = var.plan_settings["reserved"]
  
  sku {
    tier     = var.plan_settings["tier"]
    size     = var.plan_settings["size"]
    capacity = var.plan_settings["capacity"]
  }
}

resource "azurerm_app_service" "webjob" {
  name                = var.name
  location            = data.azurerm_resource_group.webjob.location
  resource_group_name = data.azurerm_resource_group.webjob.name
  app_service_plan_id = azurerm_app_service_plan.webjob.id
  app_settings        = {
                          APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.webjob.instrumentation_key}"
                          EventHubConnectionString = data.azurerm_eventhub_namespace.webjob.default_primary_connection_string
                          PartitionStatusTableName = "PartitionStatus"
                          StorageConnectionString = azurerm_storage_account.webjob.primary_connection_string
                          StorageContainerName = "event-metadata"
                          Settings__DbConnection="Server=tcp:${azurerm_sql_server.webjob.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.webjob.name};Persist Security Info=False;User ID=${azurerm_sql_server.webjob.administrator_login};Password=${azurerm_sql_server.webjob.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
                          Settings__Delay = 1
                          Settings__SkipAll = false
                          Settings__TestRun = 1
                          "Logging:LogLevel:Default" = "Trace"
                        }
}
