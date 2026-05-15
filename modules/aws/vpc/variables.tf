variable "name" {
  description = "Name prefix for VPC and child resources."
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

variable "cidr_block" {
  description = "VPC CIDR. Default /27 yields two /28 public subnets (11 usable IPs each)."
  type        = string
  default     = "10.0.0.0/27"
}

variable "az_count" {
  description = "Number of AZs to spread public subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 4
    error_message = "az_count must be between 1 and 4."
  }
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances in public subnets."
  type        = bool
  default     = true
}

variable "ssm_path_prefix" {
  description = "If set, writes outputs to SSM Parameter Store under this path. e.g. /myorg/prod/vpc."
  type        = string
  default     = null
}
