# terraform-azurerm-function-app

Terraform module that manages an [Azure](https://azure.microsoft.com/) Linux
function app together with its backing storage account and service plan. It
defaults to a consumption plan running the Python runtime and exposes the app's
default hostname.

## Usage

```hcl
module "function_app" {
  source = "github.com/moveeeax/terraform-azurerm-function-app?ref=v1.0.0"

  name                 = "prod-func01"
  service_plan_name    = "prod-func-asp"
  storage_account_name = "prodfuncsa01"
  resource_group_name  = "prod-rg"
  location             = "eastus"
  sku_name             = "EP1"
  python_version       = "3.11"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security defaults

The module fixes the following in `main.tf` rather than leaving them to the
provider or the Azure defaults:

| Setting                                             | Value      | Why                                                                    |
|-----------------------------------------------------|------------|------------------------------------------------------------------------|
| `https_only`                                        | `true`     | Azure and the provider both default this to `false`.                   |
| `site_config.ftps_state`                            | `Disabled` | `AllAllowed` would accept plaintext FTP deployments.                   |
| `site_config.minimum_tls_version`                   | `1.2`      | Pinned so a provider default change cannot silently weaken it.         |
| storage `min_tls_version`                           | `TLS1_2`   | Same, for the backing account.                                         |
| storage `allow_nested_items_to_be_public`           | `false`    | The provider defaults this to `true`, letting blobs go world-readable. |

`app_settings` values are stored in plaintext in Azure and in Terraform state.
Do not put secrets there directly — pass a
[Key Vault reference](https://learn.microsoft.com/azure/app-service/app-service-key-vault-references)
instead, for example
`API_KEY = "@Microsoft.KeyVault(SecretUri=https://<vault>.vault.azure.net/secrets/api-key/)"`.

## Runtime versions

`python_version` defaults to `3.11`. Azure Functions support for a Python
version ends when that version reaches community end of life, so `3.7`, `3.8`
and `3.9` are retired and should not be used for new apps. Versions newer than
`3.11` need a newer `azurerm` than the module's floor — `3.12` needs
>= 3.88.0, and `3.13`/`3.14` need newer still. The provider rejects an
unsupported value at plan time, not at `terraform validate`.

### Other runtimes

`application_stack` selects any runtime the provider's `application_stack`
block supports. Set exactly one version field; `use_dotnet_isolated_runtime`
goes with `dotnet_version`. When `application_stack` is set, `python_version`
is ignored. Left at `null` (the default), the module keeps rendering
`python_version` exactly as before, so upgrading never changes the runtime of
an existing app.

```hcl
module "function_app" {
  # ...

  application_stack = {
    dotnet_version              = "8.0"
    use_dotnet_isolated_runtime = true
  }
}
```

| Field                         | Type     | Notes                                             |
|-------------------------------|----------|---------------------------------------------------|
| `python_version`              | `string` | `major.minor`, checked by the module.             |
| `node_version`                | `string` | e.g. `"20"`.                                      |
| `dotnet_version`              | `string` | e.g. `"8.0"`.                                     |
| `use_dotnet_isolated_runtime` | `bool`   | Only with `dotnet_version`.                       |
| `java_version`                | `string` | e.g. `"17"`.                                      |
| `powershell_core_version`     | `string` | e.g. `"7.4"`.                                     |

Which versions are accepted depends on the azurerm release, not on this
module. At the module's floor of 3.60.0 the provider accepts only
`node_version` 12 to 18, `dotnet_version` 3.1 to 7.0 and
`powershell_core_version` 7 or 7.2; newer values such as `"20"`, `"8.0"` or
`"7.4"` need a newer azurerm. As with Python, the provider rejects an unsupported value
at plan time.

## Requirements

| Name      | Version           |
|-----------|-------------------|
| terraform | >= 1.5            |
| azurerm   | >= 3.60.0, < 6.0 |

`azurerm` 3.60.0 is the first release whose `linux_function_app` accepts a
`python_version` of `3.11`, which is this module's default. Anything older
fails at plan time, not at `terraform validate`. CI runs against the latest
azurerm 5.x release; 6.x is excluded until it has been tested.

Running the test suite in [`tests/`](tests) additionally needs Terraform or
OpenTofu >= 1.7 for `mock_provider`; the module itself does not.

## Inputs

| Name                   | Description                                                        | Type          | Default    | Required |
|------------------------|--------------------------------------------------------------------|---------------|------------|:--------:|
| `name`                 | Name of the Linux function app. Globally unique.                   | `string`      | n/a        |   yes    |
| `service_plan_name`    | Name of the service plan hosting the function app.                 | `string`      | n/a        |   yes    |
| `storage_account_name` | Name of the backing storage account. Globally unique, 3-24 lowercase letters and digits. | `string` | n/a |   yes    |
| `resource_group_name`  | Name of the resource group in which to create the resources.       | `string`      | n/a        |   yes    |
| `location`             | Azure region in which to create the resources.                     | `string`      | n/a        |   yes    |
| `sku_name`             | SKU of the service plan.                                           | `string`      | `"Y1"`     |    no    |
| `python_version`       | Python runtime version. Ignored when `application_stack` is set. `null` (with `application_stack` also `null`) omits the application stack so another runtime can be chosen through `app_settings`. | `string` | `"3.11"` | no |
| `application_stack`    | Runtime of the function app; exactly one version field. Replaces `python_version` when set (see Other runtimes). | `object` | `null` | no |
| `https_only`           | Whether the function app redirects all HTTP traffic to HTTPS.      | `bool`        | `true`     |    no    |
| `app_settings`         | Map of application settings exposed as environment variables.      | `map(string)` | `{}`       |    no    |
| `tags`                 | Map of tags applied to the resources.                              | `map(string)` | `{}`       |    no    |

## Outputs

| Name                   | Description                                    |
|------------------------|------------------------------------------------|
| `id`                   | ID of the Linux function app.                  |
| `name`                 | Name of the Linux function app.                |
| `default_hostname`     | Default hostname of the function app.          |
| `storage_account_name` | Name of the backing storage account.           |

## Tests

[`tests/defaults.tftest.hcl`](tests/defaults.tftest.hcl) runs against a mocked
provider, so it needs no Azure subscription, credentials or network access:

```console
terraform init -backend=false
terraform test
```

## License

[MIT](LICENSE)
