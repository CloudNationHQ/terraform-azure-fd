output "profile" {
  description = "contains frontdoor configuration"
  value       = lookup(var.profile, "existing", null) != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"] : azurerm_cdn_frontdoor_profile.profile["profile"]
}

output "endpoints" {
  description = "contains frontdoor endpoint configuration"
  value       = azurerm_cdn_frontdoor_endpoint.eps
}

output "custom_domains" {
  description = "contains custom domain configuration"
  value       = azurerm_cdn_frontdoor_custom_domain.domains
}

output "origin_groups" {
  description = "contains origin group configuration"
  value       = azurerm_cdn_frontdoor_origin_group.ogs
}

output "origins" {
  description = "contains origin configuration"
  value       = azurerm_cdn_frontdoor_origin.origins
}

output "routes" {
  description = "contains route configuration"
  value       = azurerm_cdn_frontdoor_route.routes
}

output "rule_sets" {
  description = "contains rule set configuration"
  value       = azurerm_cdn_frontdoor_rule_set.rule_sets
}

output "rules" {
  description = "contains rule configuration"
  value       = azurerm_cdn_frontdoor_rule.rules
}
