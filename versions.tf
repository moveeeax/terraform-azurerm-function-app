terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # >= 3.60.0: the default python_version of "3.11" is rejected by the
      # provider's own validation before v3.60.0 (accepted values there stop at
      # "3.10"), so every plan against an older provider fails.
      # < 5.0.0: no major version bump has been vetted against this module.
      version = ">= 3.60.0, < 5.0.0"
    }
  }
}
