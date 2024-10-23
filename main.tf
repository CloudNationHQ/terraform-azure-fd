# existing
data "azurerm_cdn_frontdoor_profile" "profile" {
  for_each = lookup(
    var.profile, "existing", null
  ) != null ? { "profile" = var.profile.existing } : {}

  name                = each.value.name
  resource_group_name = coalesce(lookup(each.value, "resource_group", null), var.resource_group)
}

# profile
resource "azurerm_cdn_frontdoor_profile" "profile" {
  for_each = lookup(
    var.profile, "existing", null
  ) != null ? {} : { "profile" = var.profile }

  name                = each.value.name
  resource_group_name = each.value.resource_group
  sku_name            = try(each.value.sku_name, "Standard_AzureFrontDoor")

  tags = try(
    var.profile.tags, var.tags
  )
}

# endpoints
resource "azurerm_cdn_frontdoor_endpoint" "eps" {
  for_each = lookup(
    var.profile, "existing", null
  ) != null ? var.profile.existing.endpoints : var.profile.endpoints

  name = try(
    each.value.name, join("-", [var.naming.cdn_frontdoor_endpoint, each.key])
  )

  tags = try(
    var.profile.tags, var.tags
  )

  cdn_frontdoor_profile_id = lookup(var.profile, "existing", false) != false ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
}

# custom domains
resource "azurerm_cdn_frontdoor_custom_domain" "domains" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          [for route_key, route in lookup(og, "routes", {}) :
            [for domain_key, domain in lookup(route, "custom_domains", {}) :
              {
                key         = "${endpoint_key}-${app_key}-${og_key}-${route_key}-${domain_key}"
                endpoint    = endpoint_key
                app         = app_key
                og          = og_key
                route       = route_key
                domain      = domain
                domain_name = lookup(domain, "name", null) != null ? domain.name : join("-", [var.naming.cdn_frontdoor_custom_domain, domain_key])
              }
            ]
          ]
        ]
      ]
    ]) : item.key => item
  }

  name                     = each.value.domain_name
  cdn_frontdoor_profile_id = lookup(var.profile, "existing", false) != false ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
  host_name                = each.value.domain.host_name
  dns_zone_id              = try(each.value.domain.dns_zone_id, null)

  tls {
    certificate_type    = try(each.value.domain.tls.certificate_type, "ManagedCertificate")
    minimum_tls_version = try(each.value.domain.tls.minimum_tls_version, "TLS12")
  }
}

# origin groups
resource "azurerm_cdn_frontdoor_origin_group" "origin_groups" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          {
            key      = "${endpoint_key}-${app_key}-${og_key}"
            endpoint = endpoint_key
            app      = app_key
            og       = og
            og_name  = lookup(og, "name", null) != null ? og.name : join("-", [var.naming.cdn_frontdoor_origin_group, og_key])
          }
        ]
      ]
    ]) : item.key => item
  }

  name                     = each.value.og_name
  cdn_frontdoor_profile_id = lookup(var.profile, "existing", false) != false ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id

  load_balancing {
    sample_size                 = try(each.value.og.load_balancing.sample_size, 4)
    successful_samples_required = try(each.value.og.load_balancing.successful_samples_required, 3)
  }

  health_probe {
    path                = try(each.value.og.health_probe.path, "/")
    protocol            = try(each.value.og.health_probe.protocol, "Http")
    interval_in_seconds = try(each.value.og.health_probe.interval_in_seconds, 100)
  }
}

# origins
resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          [for origin_key, origin in lookup(og, "origins", {}) :
            {
              key          = "${endpoint_key}-${app_key}-${og_key}-${origin_key}"
              endpoint     = endpoint_key
              app          = app_key
              og           = og_key
              origin       = origin
              origin_group = "${endpoint_key}-${app_key}-${og_key}"
              origin_name  = lookup(origin, "name", null) != null ? origin.name : join("-", [var.naming.cdn_frontdoor_origin, origin_key])
            }
          ]
        ]
      ]
    ]) : item.key => item
  }

  name                           = each.value.origin_name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.origin_groups[each.value.origin_group].id
  host_name                      = each.value.origin.host_name
  origin_host_header             = try(each.value.origin.origin_host_header, each.value.origin.host_name)
  priority                       = try(each.value.origin.priority, 1)
  weight                         = try(each.value.origin.weight, 1000)
  enabled                        = try(each.value.origin.enabled, true)
  certificate_name_check_enabled = try(each.value.origin.certificate_name_check_enabled, false)

  dynamic "private_link" {
    for_each = try(each.value.origin.private_link, null) != null ? [each.value.origin.private_link] : []

    content {
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
      target_type            = try(private_link.value.target_type, null)
      request_message        = try(private_link.value.request_message, null)
    }
  }
}

# routes
resource "azurerm_cdn_frontdoor_route" "routes" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          [for route_key, route in lookup(og, "routes", {}) :
            {
              key            = "${endpoint_key}-${app_key}-${og_key}-${route_key}"
              endpoint       = endpoint_key
              app            = app_key
              og             = og_key
              route          = route
              route_key      = route_key
              origin_group   = "${endpoint_key}-${app_key}-${og_key}"
              custom_domains = try(route.custom_domains, {})
              route_name     = lookup(route, "name", null) != null ? route.name : join("-", [var.naming.cdn_frontdoor_route, route_key])
            }
          ]
        ]
      ]
    ]) : item.key => item
  }

  name                          = each.value.route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.eps[each.value.endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_groups[each.value.origin_group].id

  cdn_frontdoor_origin_ids = [
    for origin in azurerm_cdn_frontdoor_origin.origins : origin.id
    if startswith(origin.name, each.value.origin_group) && origin.enabled
  ]

  cdn_frontdoor_custom_domain_ids = [
    for domain_key, domain in each.value.custom_domains :
    azurerm_cdn_frontdoor_custom_domain.domains["${each.value.endpoint}-${each.value.app}-${each.value.og}-${each.value.route_key}-${domain_key}"].id
  ]

  cdn_frontdoor_rule_set_ids = [
    for rs_key, rs in try(
      each.value.route.rule_sets, {}
    ) : azurerm_cdn_frontdoor_rule_set.rule_sets["${each.value.endpoint}-${each.value.app}-${each.value.og}-${each.value.route_key}-${rs_key}"].id
  ]

  supported_protocols    = try(each.value.route.supported_protocols, ["Http", "Https"])
  patterns_to_match      = try(each.value.route.patterns_to_match, ["/*"])
  forwarding_protocol    = try(each.value.route.forwarding_protocol, "HttpsOnly")
  link_to_default_domain = try(each.value.route.link_to_default_domain, true)
  https_redirect_enabled = try(each.value.route.https_redirect_enabled, false)

  dynamic "cache" {
    for_each = try(each.value.route.cache, null) != null ? [each.value.route.cache] : []
    content {
      query_string_caching_behavior = try(cache.value.query_string_caching_behavior, "IgnoreQueryString")
      query_strings                 = try(cache.value.query_strings, [])
      compression_enabled           = try(cache.value.compression_enabled, true)
      content_types_to_compress     = try(cache.value.content_types_to_compress, [])
    }
  }
}

# rule sets
resource "azurerm_cdn_frontdoor_rule_set" "rule_sets" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          [for route_key, route in lookup(og, "routes", {}) :
            [for rs_key, rs in lookup(route, "rule_sets", {}) :
              {
                key      = "${endpoint_key}-${app_key}-${og_key}-${route_key}-${rs_key}"
                endpoint = endpoint_key
                app      = app_key
                og       = og_key
                route    = route_key
                rs_key   = rs_key
                rs       = rs
                rs_name  = lookup(rs, "name", null) != null ? rs.name : join("", [var.naming.cdn_frontdoor_rule_set, rs_key])
              }
            ]
          ]
        ]
      ]
    ]) : item.key => item
  }

  name                     = each.value.rs_name
  cdn_frontdoor_profile_id = lookup(var.profile, "existing", false) != false ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
}

# rules
resource "azurerm_cdn_frontdoor_rule" "rules" {
  for_each = {
    for item in flatten([
      for endpoint_key, endpoint in(lookup(var.profile, "existing", null) != null ? var.profile.existing.endpoints : var.profile.endpoints) :
      [for app_key, app in lookup(endpoint, "applications", {}) :
        [for og_key, og in lookup(app, "origin_groups", {}) :
          [for route_key, route in lookup(og, "routes", {}) :
            [for rs_key, rs in lookup(route, "rule_sets", {}) :
              [for rule_key, rule in lookup(rs, "rules", {}) :
                {
                  key       = "${endpoint_key}-${app_key}-${og_key}-${route_key}-${rs_key}-${rule_key}"
                  endpoint  = endpoint_key
                  app       = app_key
                  og        = og_key
                  route     = route_key
                  rs        = rs_key
                  rule      = rule
                  rule_name = lookup(rule, "name", null) != null ? rule.name : join("", [var.naming.cdn_frontdoor_rule, rule_key])
                }
              ]
            ]
          ]
        ]
      ]
    ]) : item.key => item
  }

  name                      = each.value.rule_name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_sets["${each.value.endpoint}-${each.value.app}-${each.value.og}-${each.value.route}-${each.value.rs}"].id
  order                     = each.value.rule.order
  behavior_on_match         = try(each.value.rule.behavior_on_match, "Continue")

  actions {
    dynamic "url_redirect_action" {
      for_each = try(
        [each.value.rule.actions[0].url_redirect_action], []
      )

      content {
        redirect_type        = url_redirect_action.value.redirect_type
        destination_hostname = url_redirect_action.value.destination_hostname
        destination_path     = try(url_redirect_action.value.destination_path, "")
        query_string         = try(url_redirect_action.value.query_string, "")
        destination_fragment = try(url_redirect_action.value.destination_fragment, "")
      }
    }

    dynamic "url_rewrite_action" {
      for_each = try(
        [each.value.rule.actions[0].url_rewrite_action], []
      )

      content {
        source_pattern          = url_rewrite_action.value.source_pattern
        destination             = url_rewrite_action.value.destination
        preserve_unmatched_path = try(url_rewrite_action.value.preserve_unmatched_path, true)
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = try(
        [each.value.rule.actions[0].route_configuration_override_action], []
      )

      content {
        cdn_frontdoor_origin_group_id = try(azurerm_cdn_frontdoor_origin_group.origin_groups["${each.value.endpoint}-${each.value.app}-${each.value.og}"].id, null)
        forwarding_protocol           = try(route_configuration_override_action.value.forwarding_protocol, "MatchRequest")
        cache_duration                = try(route_configuration_override_action.value.cache_duration, "P1D")
        cache_behavior                = try(route_configuration_override_action.value.cache_behavior, "HonorOrigin")
        query_string_caching_behavior = try(route_configuration_override_action.value.query_string_caching_behavior, "IgnoreQueryString")
        compression_enabled           = try(route_configuration_override_action.value.compression_enabled, true)
      }
    }

    dynamic "response_header_action" {
      for_each = try(
        [each.value.rule.actions[0].response_header_action], []
      )

      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }

    dynamic "request_header_action" {
      for_each = try(
        [each.value.rule.actions[0].request_header_action], []
      )

      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
  }

  dynamic "conditions" {
    for_each = try(each.value.rule.conditions, null) != null ? { "default" = each.value.rule.conditions } : {}

    content {
      dynamic "remote_address_condition" {
        for_each = try(
          [conditions.value.remote_address_condition], []
        )

        content {
          operator         = remote_address_condition.value.operator
          negate_condition = try(remote_address_condition.value.negate_condition, false)
          match_values     = remote_address_condition.value.match_values
        }
      }

      dynamic "request_method_condition" {
        for_each = try(
          [conditions.value.request_method_condition], []
        )

        content {
          match_values     = request_method_condition.value.match_values
          operator         = try(request_method_condition.value.operator, "Equal")
          negate_condition = try(request_method_condition.value.negate_condition, false)
        }
      }

      dynamic "query_string_condition" {
        for_each = try(
          [conditions.value.query_string_condition], []
        )

        content {
          operator         = query_string_condition.value.operator
          negate_condition = try(query_string_condition.value.negate_condition, false)
          match_values     = try(query_string_condition.value.match_values, [])
          transforms       = try(query_string_condition.value.transforms, [])
        }
      }

      dynamic "post_args_condition" {
        for_each = try(
          [conditions.value.post_args_condition], []
        )

        content {
          operator         = post_args_condition.value.operator
          post_args_name   = post_args_condition.value.post_args_name
          transforms       = try(post_args_condition.value.transforms, [])
          match_values     = try(post_args_condition.value.match_values, [])
          negate_condition = try(post_args_condition.value.negate_condition, false)
        }
      }

      dynamic "request_uri_condition" {
        for_each = try(
          [conditions.value.request_uri_condition], []
        )

        content {
          operator         = request_uri_condition.value.operator
          negate_condition = try(request_uri_condition.value.negate_condition, false)
          match_values     = try(request_uri_condition.value.match_values, null)
          transforms       = try(request_uri_condition.value.transforms, [])
        }
      }

      dynamic "request_header_condition" {
        for_each = try(
          [conditions.value.request_header_condition], []
        )

        content {
          header_name      = request_header_condition.value.header_name
          operator         = request_header_condition.value.operator
          negate_condition = try(request_header_condition.value.negate_condition, false)
          match_values     = request_header_condition.value.match_values
          transforms       = try(request_header_condition.value.transforms, [])
        }
      }

      dynamic "request_body_condition" {
        for_each = try(
          [conditions.value.request_body_condition], []
        )

        content {
          operator         = request_body_condition.value.operator
          match_values     = request_body_condition.value.match_values
          negate_condition = try(request_body_condition.value.negate_condition, false)
          transforms       = try(request_body_condition.value.transforms, [])
        }
      }

      dynamic "request_scheme_condition" {
        for_each = try(
          [conditions.value.request_scheme_condition], []
        )

        content {
          operator         = try(request_scheme_condition.value.operator, "Equal")
          negate_condition = try(request_scheme_condition.value.negate_condition, false)
          match_values     = try(request_scheme_condition.value.match_values, [])
        }
      }

      dynamic "url_path_condition" {
        for_each = try(
          [conditions.value.url_path_condition], []
        )

        content {
          operator         = url_path_condition.value.operator
          negate_condition = try(url_path_condition.value.negate_condition, false)
          match_values     = try(url_path_condition.value.match_values, [])
          transforms       = try(url_path_condition.value.transforms, [])
        }
      }

      dynamic "url_file_extension_condition" {
        for_each = try(
          [conditions.value.url_file_extension_condition], []
        )

        content {
          operator         = url_file_extension_condition.value.operator
          negate_condition = try(url_file_extension_condition.value.negate_condition, false)
          match_values     = url_file_extension_condition.value.match_values
          transforms       = try(url_file_extension_condition.value.transforms, [])
        }
      }

      dynamic "url_filename_condition" {
        for_each = try(
          [conditions.value.url_filename_condition], []
        )

        content {
          operator         = url_filename_condition.value.operator
          negate_condition = try(url_filename_condition.value.negate_condition, false)
          match_values     = try(url_filename_condition.value.match_values, [])
          transforms       = try(url_filename_condition.value.transforms, [])
        }
      }

      dynamic "http_version_condition" {
        for_each = try(
          [conditions.value.http_version_condition], []
        )

        content {
          negate_condition = try(http_version_condition.value.negate_condition, false)
          operator         = try(http_version_condition.value.operator, "Equal")
          match_values     = http_version_condition.value.match_values
        }
      }

      dynamic "cookies_condition" {
        for_each = try(
          [conditions.value.cookies_condition], []
        )

        content {
          cookie_name      = cookies_condition.value.cookie_name
          operator         = cookies_condition.value.operator
          negate_condition = try(cookies_condition.value.negate_condition, false)
          match_values     = try(cookies_condition.value.match_values, [])
          transforms       = try(cookies_condition.value.transforms, [])
        }
      }

      dynamic "is_device_condition" {
        for_each = try(
          [conditions.value.is_device_condition], []
        )

        content {
          operator         = try(is_device_condition.value.operator, "Equal")
          negate_condition = try(is_device_condition.value.negate_condition, false)
          match_values     = try(is_device_condition.value.match_values, [])
        }
      }
    }
  }
}
