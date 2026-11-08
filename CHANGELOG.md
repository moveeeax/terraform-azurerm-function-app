# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `application_stack` input (default `null`) for Node.js, .NET (in-process or
  isolated), Java and PowerShell apps, as well as Python. Exactly one runtime
  version must be set; `use_dotnet_isolated_runtime` is only accepted with
  `dotnet_version`. When set it replaces `python_version`. Left at `null`, the
  module renders the same `python_version` block as before, so existing apps
  keep their runtime.

## [1.1.0] - 2026-11-05

### Changed

- Allow azurerm 5.x (`>= 3.60.0, < 6.0`).
- CI: bump actions to their current majors, pin OpenTofu 1.13.8, restrict the
  workflow token to `contents: read`, add Dependabot.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-function-app/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-function-app/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-function-app/releases/tag/v1.0.0
