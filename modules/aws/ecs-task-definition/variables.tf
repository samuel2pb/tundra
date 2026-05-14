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
  description = "Task CPU units."
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Task memory in MiB."
  type        = string
  default     = "1024"
}

variable "requires_compatibilities" {
  description = "Launch type compatibility. FARGATE, EC2, or both."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "container_name" {
  description = "Primary container name inside the task definition. Defaults to family."
  type        = string
  default     = null
}

variable "command" {
  description = "Override the primary container CMD. Empty list = use image default."
  type        = list(string)
  default     = []
}

variable "entrypoint" {
  description = "Override the primary container ENTRYPOINT. Empty list = use image default."
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Plain environment variables for the primary container."
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "secrets" {
  description = "Secrets injected from Secrets Manager / SSM Parameter Store into the primary container."
  type        = list(object({ name = string, valueFrom = string }))
  default     = []
}

variable "port_mappings" {
  description = "Port mappings for the primary container."
  type = list(object({
    containerPort = number
    protocol      = optional(string, "tcp")
  }))
  default = []
}

variable "health_check" {
  description = "Container-level health check for the primary container."
  type = object({
    command     = list(string)
    interval    = optional(number, 30)
    timeout     = optional(number, 5)
    retries     = optional(number, 3)
    startPeriod = optional(number, 60)
  })
  default = null
}

variable "sidecar_containers" {
  description = "Additional container definitions (e.g. cloudflared, datadog-agent). Each is a full container definition map."
  type        = list(any)
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch log group name. Defaults to /ecs/$${family}."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 7
}

variable "ephemeral_storage_gib" {
  description = "Fargate ephemeral storage in GiB. 21 = default; max 200. 0 keeps default."
  type        = number
  default     = 0
}

variable "runtime_platform" {
  description = "OS / CPU architecture."
  type = object({
    operating_system_family = string
    cpu_architecture        = string
  })
  default = {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path."
  type        = string
  default     = null
}
