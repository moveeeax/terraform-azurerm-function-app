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
    # omit the block entirely when no Python version is requested and let the
    # caller pick a stack through `app_settings` instead.
    dynamic "application_stack" {
      for_each = var.python_version == null ? [] : [var.python_version]

      content {
        python_version = application_stack.value
      }
    }
  }

  app_settings = var.app_settings

  tags = var.tags
}
