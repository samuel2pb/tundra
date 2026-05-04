data "aws_caller_identity" "current" {}

locals {
  effective_name_prefix = coalesce(var.name_prefix, var.account_name)

  effective_tags = merge(var.tags, {
    account_id   = var.account_id
    account_name = var.account_name
  })

  ssm_root    = var.ssm_path_prefix == null ? "/${var.account_name}" : var.ssm_path_prefix
  ssm_enabled = local.ssm_root != ""

  task_family       = coalesce(var.task_family, local.effective_name_prefix)
  create_task       = var.task_image != null
  platform_set      = toset(var.platform_buckets)
  datalake_arns_all = values(module.datalake_buckets.bucket_arns)

  task_platform_bucket_purposes = [
    for p in var.task_accessible_platform_buckets : p if contains(var.platform_buckets, p)
  ]

  task_platform_bucket_arns = flatten([
    for p in local.task_platform_bucket_purposes : [
      module.platform_buckets[p].bucket_arn,
      "${module.platform_buckets[p].bucket_arn}/*",
    ]
  ])

  default_task_policy_statements = length(local.task_platform_bucket_arns) > 0 ? [
    {
      sid    = "PlatformBuckets"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      resources = local.task_platform_bucket_arns
    },
  ] : []

  combined_task_policy_statements = concat(local.default_task_policy_statements, var.additional_task_policy_statements)
}

check "account_id_matches_provider" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.account_id
    error_message = "Configured AWS provider account (${data.aws_caller_identity.current.account_id}) does not match var.account_id (${var.account_id})."
  }
}

module "vpc" {
  source = "../vpc"

  name       = local.effective_name_prefix
  tags       = local.effective_tags
  cidr_block = var.vpc_cidr_block
  az_count   = var.vpc_az_count

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/vpc" : null
}

module "datalake_buckets" {
  source = "../datalake-buckets"

  name_prefix = local.effective_name_prefix
  zones       = var.datalake_zones
  tags        = local.effective_tags
  kms_key_arn = var.datalake_kms_key_arn

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/datalake" : null
}

module "platform_buckets" {
  source   = "../platform-buckets"
  for_each = local.platform_set

  name    = "${local.effective_name_prefix}-${each.key}"
  purpose = each.key
  tags    = local.effective_tags

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/buckets/${each.key}" : null
}

module "ecs_cluster" {
  source = "../ecs-cluster"

  name                      = local.effective_name_prefix
  tags                      = local.effective_tags
  default_capacity_provider = var.default_capacity_provider
  enable_container_insights = var.enable_container_insights

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/ecs/cluster" : null
}

module "iam_container_role" {
  source = "../iam-container-role"

  name_prefix                       = local.effective_name_prefix
  tags                              = local.effective_tags
  bucket_arns                       = local.datalake_arns_all
  additional_task_policy_statements = local.combined_task_policy_statements
  execution_role_kms_key_arns       = var.execution_role_kms_key_arns
  execution_role_secret_arns        = var.execution_role_secret_arns

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/iam" : null
}

module "lakeformation" {
  source = "../lakeformation"
  count  = var.enable_lakeformation ? 1 : 0

  bucket_arns = module.datalake_buckets.bucket_arns
  admin_arns  = var.lakeformation_admin_arns
  tags        = local.effective_tags

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/lakeformation" : null
}

module "ecs_task_definition" {
  source = "../ecs-task-definition"
  count  = local.create_task ? 1 : 0

  family             = local.task_family
  image              = var.task_image
  tags               = local.effective_tags
  task_role_arn      = module.iam_container_role.task_role_arn
  execution_role_arn = module.iam_container_role.execution_role_arn
  region             = var.region
  cpu                = var.task_cpu
  memory             = var.task_memory
  command            = var.task_command
  entrypoint         = var.task_entrypoint
  environment        = var.task_environment
  secrets            = var.task_secrets
  log_retention_days = var.log_retention_days

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/ecs/task" : null
}
