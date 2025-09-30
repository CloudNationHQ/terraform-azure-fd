# Changelog

## [2.0.0](https://github.com/CloudNationHQ/terraform-azure-fd/compare/v1.4.0...v2.0.0) (2025-09-30)


### ⚠ BREAKING CHANGES

* this change causes recreates

### Features

* add type definitions and changed data structure ([#22](https://github.com/CloudNationHQ/terraform-azure-fd/issues/22)) ([7e1e3c6](https://github.com/CloudNationHQ/terraform-azure-fd/commit/7e1e3c6e0e32729c20361168b5c588b120146f6a))

### Upgrade from v1.4.0 to v2.0.0:

- Update module reference to: `version = "~> 2.0"`
- The property and variable resource_group is renamed to resource_group_name 

## [1.4.0](https://github.com/CloudNationHQ/terraform-azure-fd/compare/v1.3.0...v1.4.0) (2025-01-15)


### Features

* add support for more rule conditions and response timeout seconds on the profile ([#14](https://github.com/CloudNationHQ/terraform-azure-fd/issues/14)) ([db99ff1](https://github.com/CloudNationHQ/terraform-azure-fd/commit/db99ff1faf1a3e09d31c72103d1b65b8b35b0168))
* **deps:** bump golang.org/x/net from 0.31.0 to 0.33.0 in /tests ([#16](https://github.com/CloudNationHQ/terraform-azure-fd/issues/16)) ([fb7d989](https://github.com/CloudNationHQ/terraform-azure-fd/commit/fb7d9897bc732ed5949fd67721065cc61b203db5))

## [1.3.0](https://github.com/CloudNationHQ/terraform-azure-fd/compare/v1.2.0...v1.3.0) (2025-01-06)


### Features

* add several missing properties in custom domains, origin groups and routes ([#12](https://github.com/CloudNationHQ/terraform-azure-fd/issues/12)) ([951521c](https://github.com/CloudNationHQ/terraform-azure-fd/commit/951521cf00173f7d91b1a9fb078a73e9b78c6ae4))
* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#11](https://github.com/CloudNationHQ/terraform-azure-fd/issues/11)) ([09345e7](https://github.com/CloudNationHQ/terraform-azure-fd/commit/09345e78bcbd0d6fbeee36a4ceacb6b8aeb0ad6f))
* **deps:** bump golang.org/x/crypto from 0.21.0 to 0.31.0 in /tests ([#9](https://github.com/CloudNationHQ/terraform-azure-fd/issues/9)) ([90b9856](https://github.com/CloudNationHQ/terraform-azure-fd/commit/90b9856ec64ccc594fbe45b0e3634f6a12d0253e))

## [1.2.0](https://github.com/CloudNationHQ/terraform-azure-fd/compare/v1.1.0...v1.2.0) (2024-12-11)


### Features

* incremented modules in all usages and ensured file cleanup on test failures ([#7](https://github.com/CloudNationHQ/terraform-azure-fd/issues/7)) ([3ba987c](https://github.com/CloudNationHQ/terraform-azure-fd/commit/3ba987c6ce9af9db1dda7a78943e2e9a61bc0be1))

## [1.1.0](https://github.com/CloudNationHQ/terraform-azure-fd/compare/v1.0.0...v1.1.0) (2024-11-11)


### Features

* add some missing properties ([#4](https://github.com/CloudNationHQ/terraform-azure-fd/issues/4)) ([dd533c7](https://github.com/CloudNationHQ/terraform-azure-fd/commit/dd533c78c401752bd97f383a97cfc0551c9637f1))
* enhance testing with sequential, parallel modes and flags for exceptions and skip-destroy ([#6](https://github.com/CloudNationHQ/terraform-azure-fd/issues/6)) ([e5c233d](https://github.com/CloudNationHQ/terraform-azure-fd/commit/e5c233d1809b213afc533aea7783c1e553b85145))

## 1.0.0 (2024-10-23)


### Features

* add initial resources ([#2](https://github.com/CloudNationHQ/terraform-azure-fd/issues/2)) ([018d5b8](https://github.com/CloudNationHQ/terraform-azure-fd/commit/018d5b8fd107dfc2f9f4385db21c2c7013ea75ad))
