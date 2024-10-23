locals {
  naming = {
    # lookup outputs to have consistent naming
    for type in local.naming_types : type => lookup(module.naming, type).name
  }

  naming_types = ["cdn_frontdoor_endpoint", "cdn_frontdoor_custom_domain", "cdn_frontdoor_origin_group", "cdn_frontdoor_route", "cdn_frontdoor_origin", "cdn_frontdoor_rule", "cdn_frontdoor_rule_set"]
}
