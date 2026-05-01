variable "name_prefix" {
  description = "Bucket name prefix. Final bucket name is \"$${name_prefix}-$${zone}\"."
  type        = string
}

variable "zones" {
  description = "Data lake zones to provision a bucket for."
  type        = list(string)
  default     = ["raw", "sot", "smt"]
}

variable "tags" {
  description = "Tags applied to every resource. Must include domain, platform, project."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["domain", "platform", "project"] : contains(keys(var.tags), k)])
    error_message = "tags must include domain, platform, and project."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS. If null, uses SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent object versions expire."
  type        = number
  default     = 90
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days after which incomplete multipart uploads are aborted."
  type        = number
  default     = 7
}
