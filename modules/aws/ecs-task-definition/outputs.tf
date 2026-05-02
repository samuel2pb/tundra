output "task_definition_arn" {
  description = "Task definition ARN (with revision)."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_arn_without_revision" {
  description = "Task definition ARN without revision suffix. Use this when orchestrators should always pick the latest active revision."
  value       = aws_ecs_task_definition.this.arn_without_revision
}

output "family" {
  description = "Task definition family."
  value       = aws_ecs_task_definition.this.family
}

output "revision" {
  description = "Task definition revision."
  value       = aws_ecs_task_definition.this.revision
}

output "container_name" {
  description = "Container name inside the task definition."
  value       = local.container_name
}

output "log_group_name" {
  description = "CloudWatch log group name."
  value       = aws_cloudwatch_log_group.this.name
}
