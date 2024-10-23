locals {
  naming = {
    # lookup outputs to have consistent naming
    for type in local.naming_types : type => lookup(module.naming, type).name
  }

  naming_types = ["cdn_frontdoor_route", "cdn_frontdoor_endpoint", "cdn_frontdoor_origin_group", "cdn_frontdoor_origin", "subnet", "network_security_group"]
}
