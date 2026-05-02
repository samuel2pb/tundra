variable "name" {
  description = "Bucket name. Caller is responsible for naming convention (e.g. \"$${account}-$${env}-tfstate\")."
  type        = string
}

variable "purpose" {
  description = "Bucket purpose. Drives default versioning / lifecycle / destroy protection."
  type        = string

  validation {
    condition     = contains(["tfstate", "logs", "artifacts", "athena"], var.purpose)
    error_message = "purpose must be one of: tfstate, logs, artifacts, athena."
  }
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

variable "force_destroy" {
  description = "Allow Terraform to destroy a non-empty bucket. Ignored for purpose=tfstate (always false)."
  type        = bool
  default     = false
}

variable "versioning_override" {
  description = "Override default versioning. null = use purpose default."
  type        = bool
  default     = null
}

variable "expiration_days_override" {
  description = "Override current-version expiration days. null = use purpose default. 0 = disable."
  type        = number
  default     = null
}

variable "noncurrent_expiration_days_override" {
  description = "Override noncurrent-version expiration days. null = use purpose default. 0 = disable."
  type        = number
  default     = null
}

variable "log_delivery_source_account_ids" {
  description = "When purpose=logs, account IDs allowed to deliver logs via the AWS log-delivery service principal."
  type        = list(string)
  default     = []
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path. e.g. /dodpit/prod/buckets/tfstate."
  type        = string
  default     = null
}
