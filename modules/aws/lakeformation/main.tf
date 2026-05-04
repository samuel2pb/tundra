data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# -------- Data lake settings ------------------------------------------------
# Enables hybrid access mode and allows external engines (e.g. DuckDB, Trino)
# to read/write S3 data locations with full table access.

resource "aws_lakeformation_data_lake_settings" "this" {
  admins                                = length(var.admin_arns) > 0 ? var.admin_arns : null
  allow_external_data_filtering         = true
  allow_full_table_external_data_access = true
  external_data_filtering_allow_list    = [local.account_id]
  authorized_session_tag_value_list     = ["Amazon EMR"]
}

# -------- Register S3 locations ---------------------------------------------

resource "aws_lakeformation_resource" "this" {
  for_each = var.bucket_arns

  arn                     = each.value
  use_service_linked_role = var.use_service_linked_role
  role_arn                = var.use_service_linked_role ? null : var.role_arn
  hybrid_access_enabled   = true
}
