variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "name_prefix" {
  description = "Bucket name prefix. Final bucket name is \"$${name_prefix}-$${zone}\"."
  type        = string
}

variable "zones" {
  description = "Data lake zones to provision a bucket for."
  type        = list(string)
  default     = ["raw", "sot", "smt"]
}

variable "location" {
  description = "R2 bucket location hint. Available: apac, eeur, enam, weur, wnam, oc."
  type        = string
  default     = null
}

variable "jurisdiction" {
  description = "Jurisdiction where objects are guaranteed stored. Available: default, eu, fedramp."
  type        = string
  default     = "default"
}

variable "storage_class" {
  description = "Default storage class for new objects. Available: Standard, InfrequentAccess."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "InfrequentAccess"], var.storage_class)
    error_message = "storage_class must be Standard or InfrequentAccess."
  }
}

variable "tags" {
  description = "Tags for logical grouping. Must include domain, platform, project."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["domain", "platform", "project"] : contains(keys(var.tags), k)])
    error_message = "tags must include domain, platform, and project."
  }
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days after which incomplete multipart uploads are aborted."
  type        = number
  default     = 7
}

variable "cors_allowed_origins" {
  description = "Origins allowed in CORS configuration. Pass [] to skip CORS entirely."
  type        = list(string)
  default     = []
}

variable "cors_allowed_methods" {
  description = "HTTP methods allowed in CORS configuration."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "enable_managed_domain" {
  description = "Enable public access via r2.dev managed domain."
  type        = bool
  default     = false
}

variable "enable_data_catalog" {
  description = "Enable R2 Data Catalog (managed Iceberg REST catalog) on each bucket."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Additional lifecycle rules beyond the default multipart abort. Each rule specifies a prefix, whether to delete objects, and after how many days."
  type = list(object({
    id                          = string
    prefix                      = string
    enabled                     = optional(bool, true)
    delete_after_days           = optional(number)
    transition_to_ia_after_days = optional(number)
  }))
  default = []
}
