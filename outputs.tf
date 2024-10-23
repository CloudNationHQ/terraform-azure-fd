output "profile" {
  description = "contains frontdoor configuration"
  value       = lookup(var.profile, "existing", null) != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"] : azurerm_cdn_frontdoor_profile.profile["profile"]
}

output "custom_domains" {
  description = "contains custom domain configuration"
  value = {
    for k, v in azurerm_cdn_frontdoor_custom_domain.domains :
    split("-", k)[length(split("-", k)) - 1] => {
      id = v.id
    }
  }
}
