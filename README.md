# Frontdoor

This terraform module simplifies the deployment and management of azure frontdoor, providing customizable routing and backend configurations for efficient global traffic distribution and improved application performance.

## Features

Enables configuration of new or existing frontdoor profiles

Enables multiple endpoints and applications per profile.

Allows multiple custom domains per route configuration.

Multiple origin groups per application with load balancing and health probes.

Multiple origins per origin group with priority and weighting.

Supports multiple routes per origin group.

Enables creation of multiple rule sets per route.

Multiple rules per rule set with conditions and actions.

Supports private link configurations on origins

Utilization of terratest for robust validation.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_cdn_frontdoor_custom_domain.domains](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) (resource)
- [azurerm_cdn_frontdoor_endpoint.eps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) (resource)
- [azurerm_cdn_frontdoor_origin.origins](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) (resource)
- [azurerm_cdn_frontdoor_origin_group.ogs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) (resource)
- [azurerm_cdn_frontdoor_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) (resource)
- [azurerm_cdn_frontdoor_route.routes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) (resource)
- [azurerm_cdn_frontdoor_rule.rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) (resource)
- [azurerm_cdn_frontdoor_rule_set.rule_sets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) (resource)
- [azurerm_cdn_frontdoor_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_profile) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_profile"></a> [profile](#input\_profile)

Description: contains frontdoor configuration

Type:

```hcl
object({
    name                     = optional(string)
    location                 = optional(string)
    resource_group_name      = optional(string)
    sku_name                 = optional(string, "Standard_AzureFrontDoor")
    response_timeout_seconds = optional(number, 120)
    tags                     = optional(map(string), {})
    existing                 = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    log_scrubbing_rules = optional(map(object({
      match_variable = string
    })), {})
    endpoints = optional(map(object({
      name    = optional(string)
      enabled = optional(bool, true)
      tags    = optional(map(string), {})
      applications = optional(map(object({
        origin_groups = optional(map(object({
          name                                                      = optional(string)
          session_affinity_enabled                                  = optional(bool, false)
          restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
          health_probe = optional(object({
            interval_in_seconds = optional(number, 100)
            path                = optional(string, "/")
            protocol            = optional(string, "Http")
            request_type        = optional(string, "HEAD")
          }), {})
          load_balancing = optional(object({
            additional_latency_in_milliseconds = optional(number, 50)
            sample_size                        = optional(number, 4)
            successful_samples_required        = optional(number, 3)
          }), {})
          origins = optional(map(object({
            name                           = optional(string)
            host_name                      = string
            certificate_name_check_enabled = optional(bool, true)
            enabled                        = optional(bool, true)
            http_port                      = optional(number, 80)
            https_port                     = optional(number, 443)
            origin_host_header             = optional(string)
            priority                       = optional(number, 1)
            weight                         = optional(number, 1000)
            private_link = optional(object({
              request_message        = optional(string)
              target_type            = optional(string)
              location               = string
              private_link_target_id = string
            }))
          })), {})
          routes = optional(map(object({
            name                         = optional(string)
            enabled                      = optional(bool, true)
            forwarding_protocol          = optional(string, "HttpsOnly")
            https_redirect_enabled       = optional(bool, true)
            patterns_to_match            = list(string)
            supported_protocols          = optional(list(string), ["Http", "Https"])
            cdn_frontdoor_origin_path    = optional(string)
            cdn_frontdoor_rule_set_names = optional(list(string), [])
            link_to_default_domain       = optional(bool, true)
            cache = optional(object({
              query_string_caching_behavior = optional(string, "IgnoreQueryString")
              query_strings                 = optional(list(string), [])
              compression_enabled           = optional(bool, false)
              content_types_to_compress     = optional(list(string), [])
            }), {})
            custom_domains = optional(map(object({
              name             = optional(string)
              host_name        = string
              dns_zone_id      = optional(string)
              certificate_type = optional(string, "ManagedCertificate")
              tls = optional(object({
                certificate_type        = optional(string, "ManagedCertificate")
                minimum_tls_version     = optional(string, "TLS12")
                cdn_frontdoor_secret_id = optional(string)
              }), {})
            })), {})
            rule_sets = optional(map(object({
              name = optional(string)
              rules = optional(map(object({
                name              = optional(string)
                order             = number
                behavior_on_match = optional(string)
                actions = optional(list(object({
                  url_redirect_action = optional(object({
                    redirect_type        = string
                    destination_hostname = string
                    destination_path     = optional(string)
                    query_string         = optional(string)
                    destination_fragment = optional(string)
                    redirect_protocol    = optional(string)
                  }))
                  url_rewrite_action = optional(object({
                    source_pattern          = string
                    destination             = string
                    preserve_unmatched_path = optional(bool)
                  }))
                  route_configuration_override_action = optional(object({
                    forwarding_protocol           = optional(string)
                    cache_duration                = optional(string)
                    cache_behavior                = optional(string)
                    query_string_caching_behavior = optional(string)
                    compression_enabled           = optional(bool)
                    query_string_parameters       = optional(list(string))
                    cdn_frontdoor_origin_group_id = optional(string)
                  }))
                  response_header_action = optional(object({
                    header_action = string
                    header_name   = string
                    value         = string
                  }))
                  request_header_action = optional(object({
                    header_action = string
                    header_name   = string
                    value         = string
                  }))
                })), [])
                conditions = optional(object({
                  remote_address_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = list(string)
                  }))
                  client_port_condition = optional(object({
                    operator         = string
                    match_values     = optional(list(string), [])
                    negate_condition = optional(bool, false)
                  }))
                  ssl_protocol_condition = optional(object({
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                    operator         = optional(string, "Equal")
                  }))
                  socket_address_condition = optional(object({
                    match_values     = optional(list(string), [])
                    operator         = optional(string, "IPMatch")
                    negate_condition = optional(bool, false)
                  }))
                  server_port_condition = optional(object({
                    negate_condition = optional(bool, false)
                    operator         = string
                    match_values     = list(string)
                  }))
                  host_name_condition = optional(object({
                    match_values     = optional(list(string), [])
                    operator         = string
                    transforms       = optional(list(string), [])
                    negate_condition = optional(bool, false)
                  }))
                  request_method_condition = optional(object({
                    match_values     = list(string)
                    operator         = optional(string, "Equal")
                    negate_condition = optional(bool, false)
                  }))
                  query_string_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                    transforms       = optional(list(string), [])
                  }))
                  post_args_condition = optional(object({
                    operator         = string
                    post_args_name   = string
                    transforms       = optional(list(string), [])
                    match_values     = optional(list(string), [])
                    negate_condition = optional(bool, false)
                  }))
                  request_uri_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string), [])
                  }))
                  request_header_condition = optional(object({
                    header_name      = string
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = list(string)
                    transforms       = optional(list(string), [])
                  }))
                  request_body_condition = optional(object({
                    operator         = string
                    match_values     = list(string)
                    negate_condition = optional(bool, false)
                    transforms       = optional(list(string), [])
                  }))
                  request_scheme_condition = optional(object({
                    operator         = optional(string, "Equal")
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                  }))
                  url_path_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                    transforms       = optional(list(string), [])
                  }))
                  url_file_extension_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = list(string)
                    transforms       = optional(list(string), [])
                  }))
                  url_filename_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                    transforms       = optional(list(string), [])
                  }))
                  http_version_condition = optional(object({
                    negate_condition = optional(bool, false)
                    operator         = optional(string, "Equal")
                    match_values     = list(string)
                  }))
                  cookies_condition = optional(object({
                    cookie_name      = string
                    operator         = string
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                    transforms       = optional(list(string), [])
                  }))
                  is_device_condition = optional(object({
                    operator         = optional(string, "Equal")
                    negate_condition = optional(bool, false)
                    match_values     = optional(list(string), [])
                  }))
                }), {})
              })))
            })), {})
          })), {})
        })), {})
      })), {})
    })), {})
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_naming"></a> [naming](#input\_naming)

Description: contains naming convention

Type: `map(string)`

Default: `{}`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains)

Description: contains custom domain configuration

### <a name="output_profile"></a> [profile](#output\_profile)

Description: contains frontdoor configuration
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-fd/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-fd" />
</a>

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/frontdoor/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/frontdoor/)
- [Rest Api Specs](https://github.com/hashicorp/pandora/tree/main/api-definitions/resource-manager/FrontDoor)
