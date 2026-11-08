variable "name" {
  description = "Name of the Linux function app. Must be globally unique."
  type        = string
}

variable "service_plan_name" {
  description = "Name of the service plan hosting the function app."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account backing the function app. Globally unique, 3-24 lowercase chars."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters of lowercase letters and digits only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the resources."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string
}

variable "sku_name" {
  description = "SKU of the service plan, e.g. Y1 (consumption) or EP1 (elastic premium)."
  type        = string
  default     = "Y1"
}

variable "python_version" {
  description = "Python runtime version for the function app, e.g. 3.11. Ignored when application_stack is set. Null (with application_stack also null) omits the application stack block so another runtime can be selected through app settings."
  type        = string
  default     = "3.11"

  # The azurerm provider only enforces its own list of accepted versions at plan
  # time, and only when the value is a literal -- a value arriving through a
  # variable is unknown during `terraform validate`, so a typo here otherwise
  # survives CI and fails on the first real plan. Catch the shape early.
  validation {
    condition     = var.python_version == null || can(regex("^3\\.[0-9]{1,2}$", var.python_version))
    error_message = "python_version must be null or a major.minor Python version such as \"3.11\"."
  }
}

variable "application_stack" {
  description = <<-EOT
    Runtime of the function app. Set exactly one of `python_version`,
    `node_version`, `dotnet_version`, `java_version` or
    `powershell_core_version`; `use_dotnet_isolated_runtime` is only valid
    together with `dotnet_version`. When set, this replaces `python_version`
    entirely. Null (the default) keeps using `python_version`.
  EOT

  type = object({
    python_version              = optional(string)
    node_version                = optional(string)
    dotnet_version              = optional(string)
    use_dotnet_isolated_runtime = optional(bool)
    java_version                = optional(string)
    powershell_core_version     = optional(string)
  })
  default = null

  validation {
    condition = var.application_stack == null || length([
      for v in [
        try(var.application_stack.python_version, null),
        try(var.application_stack.node_version, null),
        try(var.application_stack.dotnet_version, null),
        try(var.application_stack.java_version, null),
        try(var.application_stack.powershell_core_version, null),
      ] : v if v != null
    ]) == 1
    error_message = "application_stack must set exactly one of python_version, node_version, dotnet_version, java_version or powershell_core_version."
  }

  validation {
    condition = (
      var.application_stack == null
      || try(var.application_stack.use_dotnet_isolated_runtime, null) == null
      || try(var.application_stack.dotnet_version, null) != null
    )
    error_message = "application_stack.use_dotnet_isolated_runtime is only valid together with dotnet_version."
  }

  # Same shape check as python_version above, for the same reason. The other
  # runtimes are left to the provider's own version list.
  validation {
    condition = (
      var.application_stack == null
      || try(var.application_stack.python_version, null) == null
      || can(regex("^3\\.[0-9]{1,2}$", try(var.application_stack.python_version, "")))
    )
    error_message = "application_stack.python_version must be a major.minor Python version such as \"3.11\"."
  }
}

variable "https_only" {
  description = "Whether the function app redirects all HTTP traffic to HTTPS."
  type        = bool
  default     = true
}

variable "app_settings" {
  description = "Map of application settings exposed to the function app as environment variables."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Map of tags applied to the resources."
  type        = map(string)
  default     = {}
}
