locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_params = local.ssm_enabled ? {
    "arn"  = aws_ecs_cluster.this.arn
    "name" = aws_ecs_cluster.this.name
  } : {}
}

resource "aws_ssm_parameter" "cluster" {
  for_each = local.ssm_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}
