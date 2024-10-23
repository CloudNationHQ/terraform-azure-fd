module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "frontdoor" {
  source  = "cloudnationhq/fd/azure"
  version = "~> 1.0"

  naming = local.naming

  profile = {
    name           = module.naming.cdn_frontdoor_profile.name
    resource_group = module.rg.groups.demo.name

    endpoints = {
      main = {
        applications = {
          portal = {
            origin_groups = {
              apps = {
                origins = {
                  primary = {
                    host_name          = "example-web-app.azurewebsites.net"
                    origin_host_header = "example-web-app.azurewebsites.net"
                  }
                }
                routes = {
                  default = {
                    patterns_to_match = ["/*"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
