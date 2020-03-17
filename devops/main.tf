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

variable "app_settings" {
  description = "A key-value pair of App Settings"
  default     = {}
}

variable "site_config" {
  description = "A key-value pair for Site Config"

  default = []
}

data "azurerm_resource_group" "webjob" {
  name     = var.rg
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

  lifecycle {
    prevent_destroy = true
  }
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
  app_settings        = var.app_settings
}