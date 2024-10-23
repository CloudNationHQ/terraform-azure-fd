# Rulesets

This deploys frontdoor firewall rulesets and policies.

## Types

```hcl
profile = object({
 name           = string
 resource_group = string
 sku_name       = optional(string)
 endpoints = map(object({
   applications = map(object({
     origin_groups = map(object({
       load_balancing = optional(object({
         sample_size                 = number
         successful_samples_required = number
       }))
       health_probe = optional(object({
         path     = string
         protocol = string
       }))
       origins = map(object({
         host_name          = string
         origin_host_header = string
         priority           = optional(number)
         weight            = optional(number)
       }))
       routes = map(object({
         patterns_to_match   = list(string)
         supported_protocols = optional(list(string))
         forwarding_protocol = optional(string)
         custom_domains = optional(map(object({
           host_name = string
           tls = optional(object({
             certificate_type    = optional(string)
             minimum_tls_version = optional(string)
           }))
         })))
         cache = optional(object({
           query_string_caching_behavior = optional(string)
           compression_enabled           = optional(bool)
           content_types_to_compress     = optional(list(string))
         }))
         rule_sets = optional(map(object({
           rules = map(object({
             order             = number
             behavior_on_match = optional(string)
             actions = list(object({
               response_header_action = optional(object({
                 header_action = string
                 header_name  = string
                 value        = string
               }))
               url_redirect_action = optional(object({
                 redirect_type           = string
                 destination_hostname    = string
                 destination_path        = optional(string)
                 preserve_unmatched_path = optional(bool)
               }))
             }))
             conditions = optional(map(object({
               request_uri_condition = optional(object({
                 operator = string
               }))
             })))
           }))
         })))
       }))
     }))
   }))
 }))
})
```

## Notes

The sku name of the frontdoor firewall policy should match the sku name of the frontdoor profile.
