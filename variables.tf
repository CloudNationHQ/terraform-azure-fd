variable "profile" {
  description = "contains frontdoor configuration"
  type = object({
    name                     = optional(string)
    location                 = optional(string)
    resource_group_name      = optional(string)
    sku_name                 = optional(string)
    response_timeout_seconds = optional(number)
    tags                     = optional(map(string))
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
      enabled = optional(bool)
      tags    = optional(map(string))
      applications = optional(map(object({
        origin_groups = optional(map(object({
          name                                                      = optional(string)
          session_affinity_enabled                                  = optional(bool)
          restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number)
          health_probe = optional(object({
            interval_in_seconds = number
            path                = optional(string)
            protocol            = string
            request_type        = optional(string)
          }))
          load_balancing = optional(object({
            additional_latency_in_milliseconds = optional(number)
            sample_size                        = optional(number)
            successful_samples_required        = optional(number)
          }))
          origins = optional(map(object({
            name                           = optional(string)
            host_name                      = string
            certificate_name_check_enabled = optional(bool)
            enabled                        = optional(bool)
            http_port                      = optional(number)
            https_port                     = optional(number)
            origin_host_header             = optional(string)
            priority                       = optional(number)
            weight                         = optional(number)
            private_link = optional(object({
              request_message        = optional(string)
              target_type            = optional(string)
              location               = string
              private_link_target_id = string
            }))
          })), {})
          routes = optional(map(object({
            name                      = optional(string)
            enabled                   = optional(bool)
            forwarding_protocol       = optional(string)
            https_redirect_enabled    = optional(bool)
            patterns_to_match         = list(string)
            supported_protocols       = optional(list(string))
            cdn_frontdoor_origin_path = optional(string)
            link_to_default_domain    = optional(bool)
            cache = optional(object({
              query_string_caching_behavior = optional(string)
              query_strings                 = optional(list(string))
              compression_enabled           = optional(bool)
              content_types_to_compress     = optional(list(string))
            }))
            custom_domains = optional(map(object({
              name        = optional(string)
              host_name   = string
              dns_zone_id = optional(string)
              tls = optional(object({
                certificate_type        = optional(string)
                minimum_version         = optional(string)
                cdn_frontdoor_secret_id = optional(string)
                cipher_suite = optional(object({
                  type = string
                  custom_ciphers = optional(object({
                    tls12 = optional(set(string))
                    tls13 = optional(set(string))
                  }))
                }))
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
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                  }))
                  client_port_condition = optional(object({
                    operator         = string
                    match_values     = optional(list(string))
                    negate_condition = optional(bool)
                  }))
                  ssl_protocol_condition = optional(object({
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    operator         = optional(string)
                  }))
                  socket_address_condition = optional(object({
                    match_values     = optional(list(string))
                    operator         = optional(string)
                    negate_condition = optional(bool)
                  }))
                  server_port_condition = optional(object({
                    negate_condition = optional(bool)
                    operator         = string
                    match_values     = list(string)
                  }))
                  host_name_condition = optional(object({
                    match_values     = optional(list(string))
                    operator         = string
                    transforms       = optional(list(string))
                    negate_condition = optional(bool)
                  }))
                  request_method_condition = optional(object({
                    match_values     = list(string)
                    operator         = optional(string)
                    negate_condition = optional(bool)
                  }))
                  query_string_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  post_args_condition = optional(object({
                    operator         = string
                    post_args_name   = string
                    transforms       = optional(list(string))
                    match_values     = optional(list(string))
                    negate_condition = optional(bool)
                  }))
                  request_uri_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  request_header_condition = optional(object({
                    header_name      = string
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  request_body_condition = optional(object({
                    operator         = string
                    match_values     = list(string)
                    negate_condition = optional(bool)
                    transforms       = optional(list(string))
                  }))
                  request_scheme_condition = optional(object({
                    operator         = optional(string)
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                  }))
                  url_path_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  url_file_extension_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = list(string)
                    transforms       = optional(list(string))
                  }))
                  url_filename_condition = optional(object({
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  http_version_condition = optional(object({
                    negate_condition = optional(bool)
                    operator         = optional(string)
                    match_values     = list(string)
                  }))
                  cookies_condition = optional(object({
                    cookie_name      = string
                    operator         = string
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                    transforms       = optional(list(string))
                  }))
                  is_device_condition = optional(object({
                    operator         = optional(string)
                    negate_condition = optional(bool)
                    match_values     = optional(list(string))
                  }))
                }), {})
              })))
            })), {})
          })), {})
        })), {})
      })), {})
    })), {})
  })

  validation {
    condition     = lookup(var.profile, "resource_group_name", null) != null || var.resource_group_name != null
    error_message = "Resource group name must be provided either in the profile object or as a separate variable."
  }
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
