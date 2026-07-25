terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.60.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "function_app" {
  source = "../.."

  name                 = "example-func01"
  service_plan_name    = "example-func-asp"
  storage_account_name = "examplefuncsa01"
  resource_group_name  = "example-rg"
  location             = "eastus"
  sku_name             = "Y1"
  python_version       = "3.11"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "function_app_hostname" {
  value = module.function_app.default_hostname
}
