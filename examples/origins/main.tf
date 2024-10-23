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

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 4.0"

  naming = local.naming

  vnet = {
    name           = module.naming.virtual_network.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    cidr           = ["10.19.0.0/16"]

    subnets = {
      sn1 = {
        nsg  = {}
        cidr = ["10.19.1.0/24"]
      }
    }
  }
}

module "storage" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 2.0"

  storage = {
    name           = module.naming.storage_account.name_unique
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

    public_network_access_enabled = false
  }
}

module "private_dns" {
  source  = "cloudnationhq/pdns/azure"
  version = "~> 2.0"

  resource_group = module.rg.groups.demo.name

  zones = {
    blob = {
      name = "privatelink.blob.core.windows.net"
      virtual_network_links = {
        link1 = {
          virtual_network_id   = module.network.vnet.id
          registration_enabled = true
        }
      }
    }
  }
}

module "privatelink" {
  source  = "cloudnationhq/pe/azure"
  version = "~> 1.0"

  resource_group = module.rg.groups.demo.name
  location       = module.rg.groups.demo.location

  endpoints = {
    blob = {
      name                           = module.naming.private_endpoint.name
      subnet_id                      = module.network.subnets.sn1.id
      private_connection_resource_id = module.storage.account.id
      private_dns_zone_ids           = [module.private_dns.zones.blob.id]
      subresource_names              = ["blob"]
    }
  }
}

module "frontdoor" {
  source = "../../"

  naming = local.naming

  config = {
    name           = module.naming.cdn_frontdoor_profile.name_unique
    resource_group = module.rg.groups.demo.name
    sku_name       = "Premium_AzureFrontDoor"

    endpoints = {
      shared = {
        applications = {
          demo = {
            origin_groups = {
              primary = {
                load_balancing = {
                  sample_size                 = 4
                  successful_samples_required = 3
                }
                health_probe = {
                  path     = "/health"
                  protocol = "Https"
                }
                origins = {
                  storage = {
                    host_name                      = module.storage.account.primary_web_host
                    origin_host_header             = module.storage.account.primary_web_host
                    certificate_name_check_enabled = true
                    priority                       = 1
                    weight                         = 500
                    private_link = {
                      location               = module.rg.groups.demo.location
                      private_link_target_id = module.storage.account.id
                      target_type            = "blob"
                    }
                  }
                }
                routes = {
                  default = {
                    patterns_to_match   = ["/*"]
                    supported_protocols = ["Http", "Https"]
                    forwarding_protocol = "HttpsOnly"
                  }
                }
              }
              // another origin groups without private link
            }
          }
        }
      }
    }
  }
}

#notes
# Origin Group can only have origins with private links or origins without private links. They canot have a mix of both."
# private link request needs to be approved on the storage account
