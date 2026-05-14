variable "name" {
  description = "ECS cluster name."
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

variable "default_capacity_provider" {
  description = "Default capacity provider for tasks that do not specify one."
  type        = string
  default     = "FARGATE_SPOT"
}

variable "ec2_capacity_providers" {
  description = "EC2 Auto Scaling Group-backed capacity providers to register with the cluster."
  type = list(object({
    name                           = string
    asg_arn                        = string
    target_capacity                = optional(number, 100)
    minimum_scaling_step_size      = optional(number, 1)
    maximum_scaling_step_size      = optional(number, 1)
    managed_termination_protection = optional(bool, false)
  }))
  default = []
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the cluster."
  type        = bool
  default     = true
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path. e.g. /myorg/prod/ecs/cluster."
  type        = string
  default     = null
}
