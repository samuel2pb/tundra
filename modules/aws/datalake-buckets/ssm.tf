locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_params = local.ssm_enabled ? merge(
    { for k, b in aws_s3_bucket.this : "bucket/${k}/id" => b.id },
    { for k, b in aws_s3_bucket.this : "bucket/${k}/arn" => b.arn },
  ) : {}
}

resource "aws_ssm_parameter" "bucket" {
  for_each = local.ssm_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}
