locals {
  ssm_enabled = var.ssm_path_prefix != null
  ssm_string_params = local.ssm_enabled ? {
    "id"                      = aws_vpc.this.id
    "cidr"                    = aws_vpc.this.cidr_block
    "internet_gateway_id"     = aws_internet_gateway.this.id
    "tasks_security_group_id" = aws_security_group.tasks_egress_only.id
  } : {}
}

resource "aws_ssm_parameter" "string" {
  for_each = local.ssm_string_params

  name  = "${var.ssm_path_prefix}/${each.key}"
  type  = "String"
  value = each.value
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/${each.key}" })
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  count = local.ssm_enabled ? 1 : 0

  name  = "${var.ssm_path_prefix}/public_subnet_ids"
  type  = "StringList"
  value = join(",", aws_subnet.public[*].id)
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/public_subnet_ids" })
}

resource "aws_ssm_parameter" "availability_zones" {
  count = local.ssm_enabled ? 1 : 0

  name  = "${var.ssm_path_prefix}/availability_zones"
  type  = "StringList"
  value = join(",", aws_subnet.public[*].availability_zone)
  tags  = merge(var.tags, { Name = "${var.ssm_path_prefix}/availability_zones" })
}
