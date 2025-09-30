# existing
data "azurerm_cdn_frontdoor_profile" "profile" {
  for_each = var.profile.existing != null ? { "profile" = var.profile.existing } : {}

  name = each.value

  resource_group_name = coalesce(
    var.profile.resource_group_name, var.resource_group_name
  )
}


# profile
resource "azurerm_cdn_frontdoor_profile" "profile" {
  for_each = var.profile.existing != null ? {} : { "profile" = var.profile }

  name                     = each.value.name
  resource_group_name      = coalesce(each.value.resource_group_name, var.resource_group_name)
  sku_name                 = each.value.sku_name
  response_timeout_seconds = each.value.response_timeout_seconds

  tags = merge(var.tags, each.value.tags)

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "log_scrubbing_rule" {
    for_each = each.value.log_scrubbing_rules

    content {
      match_variable = log_scrubbing_rule.value.match_variable
    }
  }
}

# endpoints
resource "azurerm_cdn_frontdoor_endpoint" "eps" {
  for_each = coalesce(var.profile.endpoints, {})

  name = coalesce(
    each.value.name, join("-", [var.naming.cdn_frontdoor_endpoint, each.key])
  )

  tags = merge(var.tags, coalesce(each.value.tags, {}))

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
  enabled                  = each.value.enabled
}

# custom domains
resource "azurerm_cdn_frontdoor_custom_domain" "domains" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : [
            for route_key, route in coalesce(og.routes, {}) : [
              for cd_key, cd in coalesce(route.custom_domains, {}) : {
                key           = "${ep_key}-${app_key}-${og_key}-${route_key}-${cd_key}"
                endpoint      = ep_key
                app           = app_key
                og            = og_key
                route         = route_key
                custom_domain = cd
                cd_key        = cd_key
              }
            ]
          ]
        ]
      ]
    ]) : item.key => item
  }

  name = coalesce(
    each.value.custom_domain.name, join("-", [var.naming.cdn_frontdoor_custom_domain, each.value.cd_key])
  )

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
  dns_zone_id              = each.value.custom_domain.dns_zone_id
  host_name                = each.value.custom_domain.host_name

  dynamic "tls" {
    for_each = each.value.custom_domain.tls != null ? [each.value.custom_domain.tls] : []

    content {
      certificate_type        = tls.value.certificate_type
      cdn_frontdoor_secret_id = tls.value.cdn_frontdoor_secret_id
    }
  }
}

# origin groups
resource "azurerm_cdn_frontdoor_origin_group" "ogs" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : {
            key      = "${ep_key}-${app_key}-${og_key}"
            endpoint = ep_key
            app      = app_key
            og       = og
            og_key   = og_key
          }
        ]
      ]
    ]) : item.key => item
  }

  name = coalesce(
    each.value.og.name, join("-", [var.naming.cdn_frontdoor_origin_group, each.value.og_key])
  )

  cdn_frontdoor_profile_id                                  = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
  session_affinity_enabled                                  = each.value.og.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.og.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "health_probe" {
    for_each = each.value.og.health_probe != null ? [each.value.og.health_probe] : []

    content {
      interval_in_seconds = health_probe.value.interval_in_seconds
      path                = health_probe.value.path
      protocol            = health_probe.value.protocol
      request_type        = health_probe.value.request_type
    }
  }

  dynamic "load_balancing" {
    for_each = each.value.og.load_balancing != null ? [each.value.og.load_balancing] : []

    content {
      additional_latency_in_milliseconds = load_balancing.value.additional_latency_in_milliseconds
      sample_size                        = load_balancing.value.sample_size
      successful_samples_required        = load_balancing.value.successful_samples_required
    }
  }
}

# origins
resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : [
            for origin_key, origin in coalesce(og.origins, {}) : {
              key        = "${ep_key}-${app_key}-${og_key}-${origin_key}"
              endpoint   = ep_key
              app        = app_key
              og         = og_key
              origin     = origin
              origin_key = origin_key
            }
          ]
        ]
      ]
    ]) : item.key => item
  }

  name = coalesce(
    each.value.origin.name, join("-", [var.naming.cdn_frontdoor_origin, each.value.origin_key])
  )

  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.ogs["${each.value.endpoint}-${each.value.app}-${each.value.og}"].id
  enabled                        = each.value.origin.enabled
  certificate_name_check_enabled = each.value.origin.certificate_name_check_enabled
  host_name                      = each.value.origin.host_name
  http_port                      = each.value.origin.http_port
  https_port                     = each.value.origin.https_port
  origin_host_header             = each.value.origin.origin_host_header
  priority                       = each.value.origin.priority
  weight                         = each.value.origin.weight

  dynamic "private_link" {
    for_each = each.value.origin.private_link != null ? [each.value.origin.private_link] : []

    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }
}

# routes
resource "azurerm_cdn_frontdoor_route" "routes" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : [
            for route_key, route in coalesce(og.routes, {}) : {
              key       = "${ep_key}-${app_key}-${og_key}-${route_key}"
              endpoint  = ep_key
              app       = app_key
              og        = og_key
              route     = route
              route_key = route_key
            }
          ]
        ]
      ]
    ]) : item.key => item
  }

  name = coalesce(
    each.value.route.name, join(
      "-", [var.naming.cdn_frontdoor_route, each.value.route_key]
    )
  )

  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.eps[each.value.endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.ogs["${each.value.endpoint}-${each.value.app}-${each.value.og}"].id

  enabled                   = each.value.route.enabled
  forwarding_protocol       = each.value.route.forwarding_protocol
  https_redirect_enabled    = each.value.route.https_redirect_enabled
  patterns_to_match         = each.value.route.patterns_to_match
  supported_protocols       = each.value.route.supported_protocols
  link_to_default_domain    = each.value.route.link_to_default_domain
  cdn_frontdoor_origin_path = each.value.route.cdn_frontdoor_origin_path

  cdn_frontdoor_origin_ids = [for origin_key in keys(coalesce(
    var.profile.endpoints[each.value.endpoint].applications[each.value.app].origin_groups[each.value.og].origins, {}
  )) : azurerm_cdn_frontdoor_origin.origins["${each.value.endpoint}-${each.value.app}-${each.value.og}-${origin_key}"].id]

  cdn_frontdoor_custom_domain_ids = [for cd_key in keys(coalesce(
    each.value.route.custom_domains, {}
  )) : azurerm_cdn_frontdoor_custom_domain.domains["${each.value.endpoint}-${each.value.app}-${each.value.og}-${each.value.route_key}-${cd_key}"].id]

  cdn_frontdoor_rule_set_ids = [for rs_key in keys(coalesce(each.value.route.rule_sets, {})) : azurerm_cdn_frontdoor_rule_set.rule_sets["${each.value.endpoint}-${each.value.app}-${each.value.og}-${each.value.route_key}-${rs_key}"].id]

  dynamic "cache" {
    for_each = each.value.route.cache != null ? [each.value.route.cache] : []

    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

# rule sets
resource "azurerm_cdn_frontdoor_rule_set" "rule_sets" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : [
            for route_key, route in coalesce(og.routes, {}) : [
              for rs_key, rs in coalesce(route.rule_sets, {}) : {
                key      = "${ep_key}-${app_key}-${og_key}-${route_key}-${rs_key}"
                endpoint = ep_key
                app      = app_key
                og       = og_key
                route    = route_key
                rs       = rs
                rs_key   = rs_key
              }
            ]
          ]
        ]
      ]
    ]) : item.key => item
  }

  name = coalesce(
    each.value.rs.name, join("", [var.naming.cdn_frontdoor_rule_set, each.value.rs_key])
  )

  cdn_frontdoor_profile_id = var.profile.existing != null ? data.azurerm_cdn_frontdoor_profile.profile["profile"].id : azurerm_cdn_frontdoor_profile.profile["profile"].id
}

# rules
resource "azurerm_cdn_frontdoor_rule" "rules" {
  for_each = {
    for item in flatten([
      for ep_key, ep in coalesce(var.profile.endpoints, {}) : [
        for app_key, app in coalesce(ep.applications, {}) : [
          for og_key, og in coalesce(app.origin_groups, {}) : [
            for route_key, route in coalesce(og.routes, {}) : [
              for rs_key, rs in coalesce(route.rule_sets, {}) : [
                for rule_key, rule in coalesce(rs.rules, {}) : {
                  key      = "${ep_key}-${app_key}-${og_key}-${route_key}-${rs_key}-${rule_key}"
                  endpoint = ep_key
                  app      = app_key
                  og       = og_key
                  route    = route_key
                  rs       = rs_key
                  rule     = rule
                  rule_name = coalesce(
                    rule.name, join("", [var.naming.cdn_frontdoor_rule, rule_key])
                  )
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
  behavior_on_match         = each.value.rule.behavior_on_match

  actions {
    dynamic "url_redirect_action" {
      for_each = each.value.rule.actions[0].url_redirect_action != null ? [each.value.rule.actions[0].url_redirect_action] : []

      content {
        redirect_type        = url_redirect_action.value.redirect_type
        destination_hostname = url_redirect_action.value.destination_hostname
        destination_path     = url_redirect_action.value.destination_path
        query_string         = url_redirect_action.value.query_string
        destination_fragment = url_redirect_action.value.destination_fragment
        redirect_protocol    = url_redirect_action.value.redirect_protocol
      }
    }

    dynamic "url_rewrite_action" {
      for_each = each.value.rule.actions[0].url_rewrite_action != null ? [each.value.rule.actions[0].url_rewrite_action] : []

      content {
        source_pattern          = url_rewrite_action.value.source_pattern
        destination             = url_rewrite_action.value.destination
        preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
      }
    }

    dynamic "route_configuration_override_action" {
      for_each = each.value.rule.actions[0].route_configuration_override_action != null ? [each.value.rule.actions[0].route_configuration_override_action] : []

      content {
        forwarding_protocol           = route_configuration_override_action.value.forwarding_protocol
        cache_duration                = route_configuration_override_action.value.cache_duration
        cache_behavior                = route_configuration_override_action.value.cache_behavior
        query_string_caching_behavior = route_configuration_override_action.value.query_string_caching_behavior
        compression_enabled           = route_configuration_override_action.value.compression_enabled
        query_string_parameters       = route_configuration_override_action.value.query_string_parameters
        cdn_frontdoor_origin_group_id = route_configuration_override_action.value.cdn_frontdoor_origin_group_id
      }
    }

    dynamic "response_header_action" {
      for_each = each.value.rule.actions[0].response_header_action != null ? [each.value.rule.actions[0].response_header_action] : []

      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }

    dynamic "request_header_action" {
      for_each = each.value.rule.actions[0].request_header_action != null ? [each.value.rule.actions[0].request_header_action] : []

      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
  }

  conditions {
    dynamic "remote_address_condition" {
      for_each = each.value.rule.conditions.remote_address_condition != null ? [each.value.rule.conditions.remote_address_condition] : []

      content {
        operator         = remote_address_condition.value.operator
        negate_condition = remote_address_condition.value.negate_condition
        match_values     = remote_address_condition.value.match_values
      }
    }

    dynamic "client_port_condition" {
      for_each = each.value.rule.conditions.client_port_condition != null ? [each.value.rule.conditions.client_port_condition] : []

      content {
        operator         = client_port_condition.value.operator
        match_values     = client_port_condition.value.match_values
        negate_condition = client_port_condition.value.negate_condition
      }
    }

    dynamic "ssl_protocol_condition" {
      for_each = each.value.rule.conditions.ssl_protocol_condition != null ? [each.value.rule.conditions.ssl_protocol_condition] : []

      content {
        negate_condition = ssl_protocol_condition.value.negate_condition
        match_values     = ssl_protocol_condition.value.match_values
        operator         = ssl_protocol_condition.value.operator
      }
    }

    dynamic "socket_address_condition" {
      for_each = each.value.rule.conditions.socket_address_condition != null ? [each.value.rule.conditions.socket_address_condition] : []

      content {
        match_values     = socket_address_condition.value.match_values
        operator         = socket_address_condition.value.operator
        negate_condition = socket_address_condition.value.negate_condition
      }
    }

    dynamic "server_port_condition" {
      for_each = each.value.rule.conditions.server_port_condition != null ? [each.value.rule.conditions.server_port_condition] : []

      content {
        negate_condition = server_port_condition.value.negate_condition
        operator         = server_port_condition.value.operator
        match_values     = server_port_condition.value.match_values
      }
    }

    dynamic "host_name_condition" {
      for_each = each.value.rule.conditions.host_name_condition != null ? [each.value.rule.conditions.host_name_condition] : []

      content {
        match_values     = host_name_condition.value.match_values
        operator         = host_name_condition.value.operator
        transforms       = host_name_condition.value.transforms
        negate_condition = host_name_condition.value.negate_condition
      }
    }

    dynamic "request_method_condition" {
      for_each = each.value.rule.conditions.request_method_condition != null ? [each.value.rule.conditions.request_method_condition] : []

      content {
        match_values     = request_method_condition.value.match_values
        operator         = request_method_condition.value.operator
        negate_condition = request_method_condition.value.negate_condition
      }
    }

    dynamic "query_string_condition" {
      for_each = each.value.rule.conditions.query_string_condition != null ? [each.value.rule.conditions.query_string_condition] : []

      content {
        operator         = query_string_condition.value.operator
        negate_condition = query_string_condition.value.negate_condition
        match_values     = query_string_condition.value.match_values
        transforms       = query_string_condition.value.transforms
      }
    }

    dynamic "post_args_condition" {
      for_each = each.value.rule.conditions.post_args_condition != null ? [each.value.rule.conditions.post_args_condition] : []

      content {
        operator         = post_args_condition.value.operator
        post_args_name   = post_args_condition.value.post_args_name
        transforms       = post_args_condition.value.transforms
        match_values     = post_args_condition.value.match_values
        negate_condition = post_args_condition.value.negate_condition
      }
    }

    dynamic "request_uri_condition" {
      for_each = each.value.rule.conditions.request_uri_condition != null ? [each.value.rule.conditions.request_uri_condition] : []

      content {
        operator         = request_uri_condition.value.operator
        negate_condition = request_uri_condition.value.negate_condition
        match_values     = request_uri_condition.value.match_values
        transforms       = request_uri_condition.value.transforms
      }
    }

    dynamic "request_header_condition" {
      for_each = each.value.rule.conditions.request_header_condition != null ? [each.value.rule.conditions.request_header_condition] : []

      content {
        header_name      = request_header_condition.value.header_name
        operator         = request_header_condition.value.operator
        negate_condition = request_header_condition.value.negate_condition
        match_values     = request_header_condition.value.match_values
        transforms       = request_header_condition.value.transforms
      }
    }

    dynamic "request_body_condition" {
      for_each = each.value.rule.conditions.request_body_condition != null ? [each.value.rule.conditions.request_body_condition] : []

      content {
        operator         = request_body_condition.value.operator
        match_values     = request_body_condition.value.match_values
        negate_condition = request_body_condition.value.negate_condition
        transforms       = request_body_condition.value.transforms
      }
    }

    dynamic "request_scheme_condition" {
      for_each = each.value.rule.conditions.request_scheme_condition != null ? [each.value.rule.conditions.request_scheme_condition] : []

      content {
        operator         = request_scheme_condition.value.operator
        negate_condition = request_scheme_condition.value.negate_condition
        match_values     = request_scheme_condition.value.match_values
      }
    }

    dynamic "url_path_condition" {
      for_each = each.value.rule.conditions.url_path_condition != null ? [each.value.rule.conditions.url_path_condition] : []

      content {
        operator         = url_path_condition.value.operator
        negate_condition = url_path_condition.value.negate_condition
        match_values     = url_path_condition.value.match_values
        transforms       = url_path_condition.value.transforms
      }
    }

    dynamic "url_file_extension_condition" {
      for_each = each.value.rule.conditions.url_file_extension_condition != null ? [each.value.rule.conditions.url_file_extension_condition] : []

      content {
        operator         = url_file_extension_condition.value.operator
        negate_condition = url_file_extension_condition.value.negate_condition
        match_values     = url_file_extension_condition.value.match_values
        transforms       = url_file_extension_condition.value.transforms
      }
    }

    dynamic "url_filename_condition" {
      for_each = each.value.rule.conditions.url_filename_condition != null ? [each.value.rule.conditions.url_filename_condition] : []

      content {
        operator         = url_filename_condition.value.operator
        negate_condition = url_filename_condition.value.negate_condition
        match_values     = url_filename_condition.value.match_values
        transforms       = url_filename_condition.value.transforms
      }
    }

    dynamic "http_version_condition" {
      for_each = each.value.rule.conditions.http_version_condition != null ? [each.value.rule.conditions.http_version_condition] : []

      content {
        negate_condition = http_version_condition.value.negate_condition
        operator         = http_version_condition.value.operator
        match_values     = http_version_condition.value.match_values
      }
    }

    dynamic "cookies_condition" {
      for_each = each.value.rule.conditions.cookies_condition != null ? [each.value.rule.conditions.cookies_condition] : []

      content {
        cookie_name      = cookies_condition.value.cookie_name
        operator         = cookies_condition.value.operator
        negate_condition = cookies_condition.value.negate_condition
        match_values     = cookies_condition.value.match_values
        transforms       = cookies_condition.value.transforms
      }
    }

    dynamic "is_device_condition" {
      for_each = each.value.rule.conditions.is_device_condition != null ? [each.value.rule.conditions.is_device_condition] : []

      content {
        operator         = is_device_condition.value.operator
        negate_condition = is_device_condition.value.negate_condition
        match_values     = is_device_condition.value.match_values
      }
    }
  }
}
