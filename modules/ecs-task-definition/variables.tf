variable "family" {
  description = "Task definition family name."
  type        = string
}

variable "image" {
  description = "Container image URI (e.g. <ecr_url>:<tag>)."
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

variable "task_role_arn" {
  description = "ARN of the ECS task role (runtime permissions)."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role (ECR pull, log write)."
  type        = string
}

variable "region" {
  description = "AWS region (used for awslogs driver)."
  type        = string
  default     = "us-east-1"
}

variable "cpu" {
  description = "Task CPU units (Fargate)."
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Task memory in MiB (Fargate)."
  type        = string
  default     = "1024"
}

variable "container_name" {
  description = "Container name inside the task definition. Defaults to family."
  type        = string
  default     = null
}

variable "command" {
  description = "Override the container CMD. Empty list = use image default."
  type        = list(string)
  default     = []
}

variable "entrypoint" {
  description = "Override the container ENTRYPOINT. Empty list = use image default."
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Plain environment variables (non-secret)."
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "secrets" {
  description = "Secrets injected from Secrets Manager / SSM Parameter Store."
  type        = list(object({ name = string, valueFrom = string }))
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch log group name. Defaults to /ecs/${family}."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "ephemeral_storage_gib" {
  description = "Fargate ephemeral storage in GiB. 21 = default; max 200. 0 keeps default."
  type        = number
  default     = 0
}

variable "runtime_platform" {
  description = "OS / CPU architecture for Fargate."
  type = object({
    operating_system_family = string
    cpu_architecture        = string
  })
  default = {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
