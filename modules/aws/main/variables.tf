variable "name_prefix" {
  description = "Name prefix used for every child resource. Final names look like \"$${name_prefix}-vpc\", \"$${name_prefix}-raw\", \"$${name_prefix}-tfstate\", \"$${name_prefix}-cluster\"."
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

variable "region" {
  description = "AWS region used by the task definition's awslogs driver."
  type        = string
  default     = "us-east-1"
}

variable "ssm_path_prefix" {
  description = "Optional root SSM path. When set, every child module publishes outputs under sub-paths (e.g. \"$${ssm_path_prefix}/vpc\", \"$${ssm_path_prefix}/datalake\")."
  type        = string
  default     = null
}

# --- VPC -----------------------------------------------------------------

variable "vpc_cidr_block" {
  description = "VPC CIDR. Default /27 yields two /28 public subnets."
  type        = string
  default     = "10.0.0.0/27"
}

variable "vpc_az_count" {
  description = "Number of AZs to spread public subnets across."
  type        = number
  default     = 2
}

# --- Data lake buckets ---------------------------------------------------

variable "datalake_zones" {
  description = "Data lake zones to provision a bucket for."
  type        = list(string)
  default     = ["raw", "sot", "smt"]
}

variable "datalake_kms_key_arn" {
  description = "KMS key ARN for SSE-KMS on data lake buckets. null = AES256."
  type        = string
  default     = null
}

# --- Platform buckets ----------------------------------------------------

variable "platform_buckets" {
  description = "Operational bucket purposes to provision (subset of: tfstate, logs, artifacts, athena). Pass [] to skip."
  type        = list(string)
  default     = ["tfstate", "logs", "artifacts", "athena"]

  validation {
    condition     = alltrue([for p in var.platform_buckets : contains(["tfstate", "logs", "artifacts", "athena"], p)])
    error_message = "platform_buckets entries must each be one of: tfstate, logs, artifacts, athena."
  }
}

# --- ECS cluster ---------------------------------------------------------

variable "default_capacity_provider" {
  description = "ECS default capacity provider."
  type        = string
  default     = "FARGATE_SPOT"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the cluster."
  type        = bool
  default     = true
}

# --- IAM container role --------------------------------------------------

variable "additional_task_policy_statements" {
  description = "Optional extra IAM statements appended to the task policy."
  type        = any
  default     = []
}

variable "execution_role_kms_key_arns" {
  description = "Optional KMS key ARNs the execution role may use to decrypt secrets."
  type        = list(string)
  default     = []
}

variable "execution_role_secret_arns" {
  description = "Optional Secrets Manager / SSM Parameter Store ARNs the execution role may read."
  type        = list(string)
  default     = []
}

# --- Task definition (optional) ------------------------------------------

variable "task_image" {
  description = "Container image URI. When null, the task definition is not created."
  type        = string
  default     = null
}

variable "task_family" {
  description = "Task definition family. Defaults to name_prefix."
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "Task CPU units (Fargate)."
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Task memory in MiB (Fargate)."
  type        = string
  default     = "1024"
}

variable "task_command" {
  description = "Override the container CMD."
  type        = list(string)
  default     = []
}

variable "task_entrypoint" {
  description = "Override the container ENTRYPOINT."
  type        = list(string)
  default     = []
}

variable "task_environment" {
  description = "Plain environment variables (non-secret)."
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "task_secrets" {
  description = "Secrets injected from Secrets Manager / SSM Parameter Store."
  type        = list(object({ name = string, valueFrom = string }))
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 7
}
