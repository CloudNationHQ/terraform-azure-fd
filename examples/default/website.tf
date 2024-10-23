locals {
  website = {
    origin_groups = {
      primary = {
        load_balancing = {
          sample_size                 = 4
          successful_samples_required = 3
        }
        health_probe = {
          path     = "/health"
          protocol = "Https"
        }
        origins = {
          primary = {
            host_name          = "example-web-app.azurewebsites.net"
            origin_host_header = "example-web-app.azurewebsites.net"
            priority           = 1
            weight             = 1000
          }
          secondary = {
            host_name          = "example-web-app-secondary.azurewebsites.net"
            origin_host_header = "example-web-app-secondary.azurewebsites.net"
            priority           = 2
            weight             = 500
          }
        }
        routes = {
          default = {
            patterns_to_match   = ["/*"]
            supported_protocols = ["Http", "Https"]
            forwarding_protocol = "HttpsOnly"
            custom_domains = {
              primary = {
                host_name = "www.bla.com"
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
                  headers = {
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
          secondary = {
            patterns_to_match   = ["/secunda/*"]
            supported_protocols = ["Http", "Https"]
            forwarding_protocol = "HttpsOnly"
            custom_domains = {
              secondary = {
                host_name = "secunda4.example.com"
                tls = {
                  certificate_type    = "ManagedCertificate"
                  minimum_tls_version = "TLS12"
                }
              }
              tertiary = {
                host_name = "secunda5.example.com"
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
                  redirect = {
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

#locals {
#website = {
#custom_domains = {
#primary = {
#host_name = "www.example.com"
#tls = {
#certificate_type    = "ManagedCertificate"
#minimum_tls_version = "TLS12"
#}
#}
#}
#origin_groups = {
#primary = {
#load_balancing = {
#sample_size                 = 4
#successful_samples_required = 3
#}
#health_probe = {
#path     = "/health"
#protocol = "Https"
#}
#origins = {
#primary = {
#host_name          = "example-web-app.azurewebsites.net"
#origin_host_header = "example-web-app.azurewebsites.net"
#priority           = 1
#weight             = 1000
#}
#secondary = {
#host_name          = "example-web-app-secondary.azurewebsites.net"
#origin_host_header = "example-web-app-secondary.azurewebsites.net"
#priority           = 2
#weight             = 500
#}
#}
#routes = {
#default = {
#patterns_to_match   = ["/*"]
#supported_protocols = ["Http", "Https"]
#forwarding_protocol = "HttpsOnly"
#cache = {
#query_string_caching_behavior = "UseQueryString"
#compression_enabled           = true
#content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
#}
#rule_sets = {
#security = {
#rules = {
#add_security_headers = {
#order             = 1
#behavior_on_match = "Continue"
#actions = [{
#response_header_action = {
#header_action = "Append"
#header_name   = "Strict-Transport-Security"
#value         = "max-age=31536000; includeSubDomains"
#}
#}]
#}
#}
#}
#}
#}
#secondary = {
#patterns_to_match   = ["/secunda/*"]
#supported_protocols = ["Http", "Https"]
#forwarding_protocol = "HttpsOnly"
#cache = {
#query_string_caching_behavior = "UseQueryString"
#compression_enabled           = true
#content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
#}
#rule_sets = {
#redirect = {
#rules = {
#redirect_old_path = {
#order             = 1
#behavior_on_match = "Continue"
#conditions = [{
#url_path_condition = {
#operator     = "BeginsWith"
#match_values = ["/secunda/old/"]
#}
#}]
#actions = [{
#url_redirect_action = {
#redirect_type           = "Found"
#destination_hostname    = "www.example.com"
#destination_path        = "/secunda/new/"
#preserve_unmatched_path = true
#}
#}]
#}
#}
#}
#}
#}
#}
#}
#}
#}
#}

##locals {
##website = {
##custom_domains = {
##primary = {
##host_name = "www.example.com"
##tls = {
##certificate_type    = "ManagedCertificate"
##minimum_tls_version = "TLS12"
##}
##}
##}
##origin_groups = {
##primary = {
##load_balancing = {
##sample_size                 = 4
##successful_samples_required = 3
##}
##health_probe = {
##path     = "/health"
##protocol = "Https"
##}
##origins = {
##primary = {
##host_name          = "example-web-app.azurewebsites.net"
##origin_host_header = "example-web-app.azurewebsites.net"
##priority           = 1
##weight             = 1000
##}
##secondary = {
##host_name          = "example-web-app-secondary.azurewebsites.net"
##origin_host_header = "example-web-app-secondary.azurewebsites.net"
##priority           = 2
##weight             = 500
##}
##}
##routes = {
##default = {
##patterns_to_match   = ["/*"]
##supported_protocols = ["Http", "Https"]
##forwarding_protocol = "HttpsOnly"
##cache = {
##query_string_caching_behavior = "UseQueryString"
##compression_enabled           = true
##content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
##}
##}
##secundary = {
##patterns_to_match   = ["/secunda/*"]
##supported_protocols = ["Http", "Https"]
##forwarding_protocol = "HttpsOnly"
##cache = {
##query_string_caching_behavior = "UseQueryString"
##compression_enabled           = true
##content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
##}
##}
### You can add more routes here if needed
##}
##}
### You can add more origin groups here if needed
##}
##}
##}


#locals {
#website = {
#custom_domains = {
#primary = {
#host_name = "www.example.com"
#tls = {
#certificate_type    = "ManagedCertificate"
#minimum_tls_version = "TLS12"
#}
#}
#}
#origin_groups = {
#primary = {
#load_balancing = {
#sample_size                 = 4
#successful_samples_required = 3
#}
#health_probe = {
#path     = "/health"
#protocol = "Https"
#}
#origins = {
#primary = {
#host_name          = "example-web-app.azurewebsites.net"
#origin_host_header = "example-web-app.azurewebsites.net"
#priority           = 1
#weight             = 1000
#}
#secondary = {
#host_name          = "example-web-app-secondary.azurewebsites.net"
#origin_host_header = "example-web-app-secondary.azurewebsites.net"
#priority           = 2
#weight             = 500
#}
#}
#}
#}
#routes = {
#default = {
#patterns_to_match   = ["/*"]
#supported_protocols = ["Http", "Https"]
#forwarding_protocol = "HttpsOnly"
#cache = {
#query_string_caching_behavior = "UseQueryString"
#compression_enabled           = true
#content_types_to_compress     = ["text/html", "text/javascript", "text/css", "text/plain"]
#}
#}
#}
#}
#}
