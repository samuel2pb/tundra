variable "bucket_arns" {
  description = "Map of zone/purpose => S3 bucket ARN to register as Lake Formation data locations."
  type        = map(string)
}

variable "admin_arns" {
  description = "IAM principal ARNs granted Lake Formation admin. When empty, no admins are configured beyond the default."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource. Must include domain, platform, project."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["domain", "platform", "project"] : contains(keys(var.tags), k)])
    error_message = "tags must include domain, platform, and project."
  }
}

variable "use_service_linked_role" {
  description = "When true, registers locations using the Lake Formation SLR. When false, you must pass a custom role_arn."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Custom IAM role ARN for Lake Formation to access S3. Only used when use_service_linked_role is false."
  type        = string
  default     = null
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path."
  type        = string
  default     = null
}
