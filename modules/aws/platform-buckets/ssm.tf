locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_params = local.ssm_enabled ? {
    "id"   = aws_s3_bucket.this.id
    "arn"  = aws_s3_bucket.this.arn
    "fqdn" = aws_s3_bucket.this.bucket_regional_domain_name
  } : {}
}

resource "aws_ssm_parameter" "bucket" {
  for_each = local.ssm_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}
