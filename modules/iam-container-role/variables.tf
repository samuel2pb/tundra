variable "name_prefix" {
  description = "Name prefix for the IAM roles and policies."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource. Must include domain, platform, project."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["domain", "platform", "project"] : contains(keys(var.tags), k)])
    error_message = "tags must include domain, platform, and project."
  }
}

variable "bucket_arns" {
  description = "S3 bucket ARNs the task is allowed to read/write. Both the bucket and bucket/* are granted."
  type        = list(string)
}

variable "additional_task_policy_statements" {
  description = "Optional extra IAM statements appended to the task policy."
  type        = any
  default     = []
}

variable "execution_role_kms_key_arns" {
  description = "Optional KMS key ARNs the execution role may use to decrypt (e.g. SSM parameter or Secrets Manager keys)."
  type        = list(string)
  default     = []
}

variable "execution_role_secret_arns" {
  description = "Optional Secrets Manager / SSM Parameter Store ARNs the execution role may read for container secrets injection."
  type        = list(string)
  default     = []
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path. e.g. /dodpit/prod/iam/awebo."
  type        = string
  default     = null
}
