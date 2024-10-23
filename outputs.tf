output "profile" {
  value = azurerm_cdn_frontdoor_profile.profile
}

#output "custom_domains" {
  #value = azurerm_cdn_frontdoor_custom_domain.domains
#}

output "custom_domains" {
  value = {
    for k, v in azurerm_cdn_frontdoor_custom_domain.domains :
    split("-", k)[length(split("-", k)) - 1] => {
      id = v.id
    }
  }
}
