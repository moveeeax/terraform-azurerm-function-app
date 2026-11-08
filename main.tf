locals {
  # `application_stack` wins when set. Otherwise `python_version` is expanded
  # into the same shape, so the default ("3.11", no application_stack) renders
  # the exact block earlier releases did and existing apps plan unchanged.
  application_stack = var.application_stack != null ? var.application_stack : (
    var.python_version == null ? null : {
      python_version              = var.python_version
      node_version                = null
      dotnet_version              = null
      use_dotnet_isolated_runtime = null
      java_version                = null
      powershell_core_version     = null
    }
  )
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  # The function app's content and runtime state live in this account. Nothing
  # in it should ever be world-readable, so deny containers and blobs the
  # ability to opt into anonymous public access (the provider default is true).
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  https_only = var.https_only

  site_config {
    # Stated explicitly rather than relying on the provider defaults so the
    # posture is part of the module's contract: no plaintext FTP, no TLS < 1.2.
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"

    # `application_stack` accepts exactly one runtime argument. Emitting the
    # block with every argument unset leaves the app's runtime unmanaged, so
    # omit the block entirely when no runtime is requested and let the caller
    # pick a stack through `app_settings` instead.
    dynamic "application_stack" {
      for_each = local.application_stack == null ? [] : [local.application_stack]

      content {
        python_version              = application_stack.value.python_version
        node_version                = application_stack.value.node_version
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version                = application_stack.value.java_version
        powershell_core_version     = application_stack.value.powershell_core_version
      }
    }
  }

  app_settings = var.app_settings

  tags = var.tags
}
