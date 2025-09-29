variable "profile" {
  description = "contains frontdoor configuration"
  type = object({
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
}

variable "naming" {
  description = "contains naming convention"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}

