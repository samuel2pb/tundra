variable "name" {
  description = "ECS service name."
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

variable "cluster_arn" {
  description = "ECS cluster ARN."
  type        = string
}

variable "task_definition_arn" {
  description = "Task definition ARN (without revision to always use latest)."
  type        = string
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy entries."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
}

variable "subnet_ids" {
  description = "Subnet IDs for task network interfaces."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for task network interfaces."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to task ENIs."
  type        = bool
  default     = true
}

variable "enable_circuit_breaker" {
  description = "Enable deployment circuit breaker with rollback."
  type        = bool
  default     = true
}

variable "force_new_deployment" {
  description = "Force new deployment on every apply."
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for service to reach steady state on apply."
  type        = bool
  default     = false
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path."
  type        = string
  default     = null
}
