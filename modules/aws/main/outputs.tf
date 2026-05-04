output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "tasks_security_group_id" {
  description = "Egress-only security group for Fargate tasks."
  value       = module.vpc.tasks_security_group_id
}

output "datalake_bucket_ids" {
  description = "Map of zone => data lake bucket id."
  value       = module.datalake_buckets.bucket_ids
}

output "datalake_bucket_arns" {
  description = "Map of zone => data lake bucket ARN."
  value       = module.datalake_buckets.bucket_arns
}

output "platform_bucket_ids" {
  description = "Map of purpose => operational bucket id."
  value       = { for k, m in module.platform_buckets : k => m.bucket_id }
}

output "platform_bucket_arns" {
  description = "Map of purpose => operational bucket ARN."
  value       = { for k, m in module.platform_buckets : k => m.bucket_arn }
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_cluster.cluster_name
}

output "task_role_arn" {
  description = "Task IAM role ARN."
  value       = module.iam_container_role.task_role_arn
}

output "execution_role_arn" {
  description = "Task execution IAM role ARN."
  value       = module.iam_container_role.execution_role_arn
}

output "lakeformation_registered_arns" {
  description = "Map of zone => S3 ARN registered as Lake Formation data location. null when enable_lakeformation is false."
  value       = var.enable_lakeformation ? module.lakeformation[0].registered_resource_arns : null
}

output "task_definition_arn" {
  description = "Task definition ARN. null when task_image was not provided."
  value       = local.create_task ? module.ecs_task_definition[0].task_definition_arn : null
}

output "task_definition_arn_without_revision" {
  description = "Task definition ARN without revision. null when task_image was not provided."
  value       = local.create_task ? module.ecs_task_definition[0].task_definition_arn_without_revision : null
}

output "log_group_name" {
  description = "CloudWatch log group name for the task. null when task_image was not provided."
  value       = local.create_task ? module.ecs_task_definition[0].log_group_name : null
}
