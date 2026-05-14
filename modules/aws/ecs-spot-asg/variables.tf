variable "name" {
  description = "Name prefix for ASG, launch template, and instance profile."
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

variable "cluster_name" {
  description = "ECS cluster name. Injected into instance user data."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ASG instances."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to ASG instances."
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types for mixed instances policy, ordered by preference."
  type        = list(string)
  default     = ["t4g.small", "t4g.medium"]
}

variable "ami_type" {
  description = "AMI type: bottlerocket or al2023."
  type        = string
  default     = "bottlerocket"

  validation {
    condition     = contains(["bottlerocket", "al2023"], var.ami_type)
    error_message = "ami_type must be bottlerocket or al2023."
  }
}

variable "ami_architecture" {
  description = "CPU architecture for AMI lookup."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.ami_architecture)
    error_message = "ami_architecture must be arm64 or x86_64."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 3
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy."
  type        = string
  default     = "capacity-optimized"
}

variable "on_demand_base_capacity" {
  description = "Number of on-demand instances before using Spot."
  type        = number
  default     = 0
}

variable "on_demand_percentage" {
  description = "Percentage of on-demand instances above base capacity."
  type        = number
  default     = 0
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 30
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Null = no SSH."
  type        = string
  default     = null
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path."
  type        = string
  default     = null
}
