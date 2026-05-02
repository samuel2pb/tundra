variable "account_id" {
  description = "AWS account ID this stack is deployed into. Used to validate the active provider, propagated as a resource tag, and inserted into the default ssm_path_prefix."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "account_name" {
  description = "Short, friendly name for the account (e.g. \"prod\", \"dodpit\"). Used as the default name prefix for every child resource and inserted into the default ssm_path_prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.account_name))
    error_message = "account_name must be lowercase alphanumeric and dashes, starting with a letter or digit."
  }
}

variable "tags" {
  description = "Caller-supplied tags. Must include domain, platform, project. The module merges account_id and account_name on top automatically."
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

variable "name_prefix" {
  description = "Override for the name prefix used on every child resource. When null (default), the module uses var.account_name."
  type        = string
  default     = null
}

variable "ssm_path_prefix" {
  description = "Override for the root SSM path. When null (default), the module uses \"/$${account_name}\". Pass an explicit value to use a different layout, or pass an empty string to disable SSM publication entirely."
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
  description = "Optional extra IAM statements appended to the task policy. These are merged on top of the module's own defaults (RW on the platform buckets listed in var.task_accessible_platform_buckets)."
  type        = any
  default     = []
}

variable "task_accessible_platform_buckets" {
  description = "Platform-bucket purposes the task role should be granted S3 read/write on. Each entry must also be present in var.platform_buckets to take effect. Pass [] to disable the default platform-bucket grant."
  type        = list(string)
  default     = ["athena", "artifacts"]

  validation {
    condition     = alltrue([for p in var.task_accessible_platform_buckets : contains(["tfstate", "logs", "artifacts", "athena"], p)])
    error_message = "task_accessible_platform_buckets entries must each be one of: tfstate, logs, artifacts, athena."
  }
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
  description = "Task definition family. Defaults to the effective name prefix."
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
