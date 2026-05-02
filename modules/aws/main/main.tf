locals {
  ssm_root          = var.ssm_path_prefix
  ssm_enabled       = local.ssm_root != null
  task_family       = coalesce(var.task_family, var.name_prefix)
  create_task       = var.task_image != null
  platform_set      = toset(var.platform_buckets)
  datalake_arns_all = values(module.datalake_buckets.bucket_arns)
}

module "vpc" {
  source = "../vpc"

  name       = var.name_prefix
  tags       = var.tags
  cidr_block = var.vpc_cidr_block
  az_count   = var.vpc_az_count

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/vpc" : null
}

module "datalake_buckets" {
  source = "../datalake-buckets"

  name_prefix = var.name_prefix
  zones       = var.datalake_zones
  tags        = var.tags
  kms_key_arn = var.datalake_kms_key_arn

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/datalake" : null
}

module "platform_buckets" {
  source   = "../platform-buckets"
  for_each = local.platform_set

  name    = "${var.name_prefix}-${each.key}"
  purpose = each.key
  tags    = var.tags

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/buckets/${each.key}" : null
}

module "ecs_cluster" {
  source = "../ecs-cluster"

  name                      = var.name_prefix
  tags                      = var.tags
  default_capacity_provider = var.default_capacity_provider
  enable_container_insights = var.enable_container_insights

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/ecs/cluster" : null
}

module "iam_container_role" {
  source = "../iam-container-role"

  name_prefix                       = var.name_prefix
  tags                              = var.tags
  bucket_arns                       = local.datalake_arns_all
  additional_task_policy_statements = var.additional_task_policy_statements
  execution_role_kms_key_arns       = var.execution_role_kms_key_arns
  execution_role_secret_arns        = var.execution_role_secret_arns

  ssm_path_prefix = local.ssm_enabled ? "${local.ssm_root}/iam" : null
}

module "ecs_task_definition" {
  source = "../ecs-task-definition"
  count  = local.create_task ? 1 : 0

  family             = local.task_family
  image              = var.task_image
  tags               = var.tags
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
