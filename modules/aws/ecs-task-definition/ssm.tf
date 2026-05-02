locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_params = local.ssm_enabled ? {
    "task_definition_arn"                  = aws_ecs_task_definition.this.arn
    "task_definition_arn_without_revision" = aws_ecs_task_definition.this.arn_without_revision
    "family"                               = aws_ecs_task_definition.this.family
    "container_name"                       = local.container_name
    "log_group_name"                       = aws_cloudwatch_log_group.this.name
  } : {}
}

resource "aws_ssm_parameter" "task" {
  for_each = local.ssm_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}
