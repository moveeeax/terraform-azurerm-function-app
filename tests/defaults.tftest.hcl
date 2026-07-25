# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for `mock_provider`. The module's
# own `required_version` is deliberately left at >= 1.5 so consumers on older
# CLIs are not broken by a test-only dependency.
#
# `mock_provider` means these runs need no Azure credentials and no network.

mock_provider "azurerm" {
  # OpenTofu resolves mocked computed attributes to concrete random strings at
  # plan time, where Terraform leaves them unknown. The provider parses
  # service_plan_id, so it has to be given a syntactically real resource ID or
  # the runs fail on the mock value rather than on anything this module does.
  mock_resource "azurerm_service_plan" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Web/serverFarms/example-func-asp"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Storage/storageAccounts/examplefuncsa01"
      primary_access_key = "mock-storage-account-key"
    }
  }
}

variables {
  name                 = "example-func01"
  service_plan_name    = "example-func-asp"
  storage_account_name = "examplefuncsa01"
  resource_group_name  = "example-rg"
  location             = "eastus"
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = azurerm_linux_function_app.this.https_only == true
    error_message = "The function app must reject plaintext HTTP by default."
  }

  assert {
    condition     = azurerm_linux_function_app.this.site_config[0].ftps_state == "Disabled"
    error_message = "FTP/FTPS must be disabled; AllAllowed would permit plaintext FTP."
  }

  assert {
    condition     = azurerm_linux_function_app.this.site_config[0].minimum_tls_version == "1.2"
    error_message = "The function app must require TLS 1.2 or better."
  }

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "The backing storage account must require TLS 1.2 or better."
  }

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Containers and blobs in the backing storage account must not be able to opt into anonymous public access."
  }

  assert {
    condition     = azurerm_service_plan.this.os_type == "Linux"
    error_message = "This module manages a Linux function app."
  }
}

run "python_stack_is_wired_through" {
  command = plan

  variables {
    python_version = "3.10"
  }

  assert {
    condition     = length(azurerm_linux_function_app.this.site_config[0].application_stack) == 1
    error_message = "A requested python_version must produce exactly one application_stack block."
  }

  assert {
    condition     = azurerm_linux_function_app.this.site_config[0].application_stack[0].python_version == "3.10"
    error_message = "python_version must be passed through to the application stack."
  }
}

run "null_python_version_omits_the_application_stack" {
  command = plan

  variables {
    python_version = null
  }

  # `application_stack` requires exactly one runtime argument, so an empty block
  # must never be emitted -- the block has to disappear completely instead.
  assert {
    condition     = length(azurerm_linux_function_app.this.site_config[0].application_stack) == 0
    error_message = "A null python_version must omit the application_stack block entirely."
  }
}

run "https_only_can_be_opted_out_of_explicitly" {
  command = plan

  variables {
    https_only = false
  }

  assert {
    condition     = azurerm_linux_function_app.this.https_only == false
    error_message = "https_only must remain caller-controllable."
  }
}

run "rejects_malformed_python_version" {
  command = plan

  variables {
    python_version = "3.11.4"
  }

  expect_failures = [var.python_version]
}

run "rejects_invalid_storage_account_name" {
  command = plan

  variables {
    storage_account_name = "Example-Func-SA-01"
  }

  expect_failures = [var.storage_account_name]
}
