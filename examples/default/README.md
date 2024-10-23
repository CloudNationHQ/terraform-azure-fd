# Default

This example illustrates the default setup, in its simplest form.

## Types

```hcl
profile = object({
  name           = string
  resource_group = string
  endpoints = map(object({
    applications = map(object({
      origin_groups = map(object({
        origins = map(object({
          host_name          = string
          origin_host_header = string
        }))
        routes = map(object({
          patterns_to_match = list(string)
        }))
      }))
    }))
  }))
})
```
