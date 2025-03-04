variable "profile" {
  description = "contains frontdoor configuration"
  type        = any
}

variable "naming" {
  description = "contains naming convention"
  type        = map(string)
  default     = {}
}

variable "resource_group" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
