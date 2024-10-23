#locals {
  #api = {
    #custom_domains = {
      #primary = {
        #host_name = "api.example.com"
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
            #host_name          = "primary-api.azurewebsites.net"
            #origin_host_header = "primary-api.azurewebsites.net"
            #priority           = 1
            #weight             = 1000
          #}
          #secondary = {
            #host_name          = "secondary-api.azurewebsites.net"
            #origin_host_header = "secondary-api.azurewebsites.net"
            #priority           = 2
            #weight             = 500
          #}
        #}
      #}
    #}
    #routes = {
      #v1 = {
        #patterns_to_match   = ["/api/v1/*"]
        #supported_protocols = ["Https"]
        #forwarding_protocol = "HttpsOnly"
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
          #versioning = {
            #rules = {
              #redirect_old_version = {
                #order             = 1
                #behavior_on_match = "Continue"
                #conditions = [{
                  #url_path_condition = {
                    #operator     = "BeginsWith"
                    #match_values = ["/api/v1/"]
                  #}
                #}]
                #actions = [{
                  #url_redirect_action = {
                    #redirect_type        = "Moved"
                    #destination_hostname = "api.example.com"
                    #destination_path     = "/api/v2/"
                  #}
                #}]
              #}
            #}
          #}
          #rate = {
            #rules = {
              #limit_requests = {
                #order             = 1
                #behavior_on_match = "Continue"
                #actions = [{
                  #route_configuration_override_action = {
                    #cache_duration = "00:00:05"
                    ##cache_behavior = "BypassCache"
                    ##query_string_caching_behavior = "IgnoreQueryString"
                  #}
                #}]
                #conditions = [{
                  #request_header_condition = {
                    #header_name  = "X-API-Key"
                    #operator     = "Equal"
                    #match_values = [""] # This should be replaced with actual API key logic
                  #}
                #}]
              #}
            #}
          #}
        #}
      #}
      #v2 = {
        #patterns_to_match   = ["/api/v2/*"]
        #supported_protocols = ["Https"]
        ##forwarding_protocol = "HttpsOnly"
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
          #rate = {
            #rules = {
              #limit_requests = {
                #order             = 1
                #behavior_on_match = "Continue"
                #actions = [{
                  #route_configuration_override_action = {
                    #cache_duration = "00:00:05"
                    ##cache_behavior = "BypassCache"
                    ##query_string_caching_behavior = "IgnoreQueryString"
                  #}
                #}]
                #conditions = [{
                  #request_header_condition = {
                    #header_name  = "X-API-Key"
                    #operator     = "Equal"
                    #match_values = [""] # This should be replaced with actual API key logic
                  #}
                #}]
              #}
            #}
          #}
        #}
      #}
      #public = {
        #patterns_to_match   = ["/public/*"]
        #supported_protocols = ["Http", "Https"]
        ##forwarding_protocol = "HttpsOnly"
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
    #}
  #}
#}
