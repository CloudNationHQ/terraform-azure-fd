locals {
  portal = {
    origin_groups = {
      apps = {
        load_balancing = {
          sample_size                 = 4
          successful_samples_required = 3
        }
        health_probe = {
          path     = "/health"
          protocol = "Https"
        }
        origins = {
          west = {
            host_name          = "example-web-app.azurewebsites.net"
            origin_host_header = "example-web-app.azurewebsites.net"
            priority           = 1
            weight             = 1000
          }
          north = {
            host_name          = "example-web-app-secondary.azurewebsites.net"
            origin_host_header = "example-web-app-secondary.azurewebsites.net"
            priority           = 2
            weight             = 500
          }
        }
        routes = {
          main = {
            patterns_to_match   = ["/*"]
            supported_protocols = ["Http", "Https"]
            forwarding_protocol = "HttpsOnly"
            custom_domains = {
              portal = {
                host_name = "www.portal.com"
                tls = {
                  certificate_type    = "ManagedCertificate"
                  minimum_tls_version = "TLS12"
                }
              }
            }
            cache = {
              query_string_caching_behavior = "UseQueryString"
              compression_enabled           = true
              content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
            }
            rule_sets = {
              security = {
                rules = {
                  hsts = {
                    order             = 1
                    behavior_on_match = "Continue"
                    actions = [{
                      response_header_action = {
                        header_action = "Append"
                        header_name   = "Strict-Transport-Security"
                        value         = "max-age=31536000; includeSubDomains"
                      }
                    }]
                    conditions = {
                      request_uri_condition = {
                        operator = "Any"
                      }
                    }
                  }
                }
              }
            }
          }
          legacy = {
            patterns_to_match   = ["/secunda/*"]
            supported_protocols = ["Http", "Https"]
            forwarding_protocol = "HttpsOnly"
            custom_domains = {
              web = {
                host_name = "web.example.com"
                tls = {
                  certificate_type    = "ManagedCertificate"
                  minimum_tls_version = "TLS12"
                }
              }
              backup = {
                host_name = "backup.example.com"
                tls = {
                  certificate_type    = "ManagedCertificate"
                  minimum_tls_version = "TLS12"
                }
              }
            }
            cache = {
              query_string_caching_behavior = "UseQueryString"
              compression_enabled           = true
              content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
            }
            rule_sets = {
              redirect = {
                rules = {
                  forward = {
                    order             = 1
                    behavior_on_match = "Continue"
                    actions = [{
                      url_redirect_action = {
                        redirect_type           = "Found"
                        destination_hostname    = "www.example.com"
                        destination_path        = "/secunda/new/"
                        preserve_unmatched_path = true
                      }
                    }]
                    conditions = {
                      request_uri_condition = {
                        operator = "Any"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
