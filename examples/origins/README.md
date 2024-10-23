# Origins

This deploys frontdoor origins and several subresources

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
         host_name                      = string
         origin_host_header             = string
         certificate_name_check_enabled = optional(bool)
         priority                       = optional(number)
         weight                        = optional(number)
         private_link = optional(object({
           location               = string
           private_link_target_id = string
           target_type           = string
         }))
       }))
       routes = map(object({
         patterns_to_match   = list(string)
         supported_protocols = optional(list(string))
         forwarding_protocol = optional(string)
       }))
     }))
   }))
 }))
})
```

## Notes

Origin Group can only have origins with private links or origins without private links. They canot have a mix of both.

Private link request needs to be approved at the resource level
