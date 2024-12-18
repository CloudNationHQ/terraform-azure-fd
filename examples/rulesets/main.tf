module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.22"

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

module "policy" {
  source  = "cloudnationhq/fdfwp/azure"
  version = "~> 1.0"

  config = {
    name           = module.naming.cdn_frontdoor_firewall_policy.name
    frontdoor_id   = module.frontdoor.profile.id
    resource_group = module.rg.groups.demo.name
    sku_name       = "Premium_AzureFrontDoor"

    policy = {
      mode = "Prevention"
    }

    managed_rules = {
      default = {
        type    = "DefaultRuleSet"
        version = "1.0"
      }
      botprotection = {
        type    = "Microsoft_BotManagerRuleSet"
        version = "1.0"
      }
    }

    security_policy = {
      name = module.naming.cdn_frontdoor_security_policy.name

      associations = {
        main = {
          patterns_to_match = ["/*"]
          domains = {
            website = {
              domain_id = module.frontdoor.custom_domains.portal.id
            }
            another = {
              domain_id = module.frontdoor.custom_domains.backup.id
            }
          }
        }
      }
    }
  }
}

module "frontdoor" {
  source  = "cloudnationhq/fd/azure"
  version = "~> 1.0"

  naming = local.naming

  profile = {
    name           = module.naming.cdn_frontdoor_profile.name_unique
    resource_group = module.rg.groups.demo.name
    sku_name       = "Premium_AzureFrontDoor"

    endpoints = {
      demo = {
        name = module.naming.cdn_frontdoor_endpoint.name_unique
        applications = {
          portal = local.portal
        }
      }
    }
  }
}
