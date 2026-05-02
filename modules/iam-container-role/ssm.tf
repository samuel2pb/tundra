locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_params = local.ssm_enabled ? {
    "task_role_arn"       = aws_iam_role.task.arn
    "task_role_name"      = aws_iam_role.task.name
    "execution_role_arn"  = aws_iam_role.execution.arn
    "execution_role_name" = aws_iam_role.execution.name
  } : {}
}

resource "aws_ssm_parameter" "role" {
  for_each = local.ssm_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}
