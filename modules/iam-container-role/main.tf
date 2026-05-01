data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  bucket_object_arns = [for a in var.bucket_arns : "${a}/*"]
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# -------- Task role (used by the application container at runtime) --------

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-task-role" })
}

data "aws_iam_policy_document" "task" {
  statement {
    sid     = "S3BucketLevel"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketLocation",
    ]
    resources = var.bucket_arns
  }

  statement {
    sid     = "S3ObjectLevel"
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = local.bucket_object_arns
  }

  # Glue Data Catalog: account-wide read/write. Granted on catalog, databases,
  # tables, partitions, and user-defined functions.
  statement {
    sid     = "GlueCatalogReadWrite"
    effect  = "Allow"
    actions = [
      "glue:GetCatalogImportStatus",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:DeleteDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchGetPartition",
      "glue:BatchUpdatePartition",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:UpdatePartition",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions",
      "glue:CreateUserDefinedFunction",
      "glue:UpdateUserDefinedFunction",
      "glue:DeleteUserDefinedFunction",
      "glue:SearchTables",
    ]
    resources = [
      "arn:${local.partition}:glue:${local.region}:${local.account_id}:catalog",
      "arn:${local.partition}:glue:${local.region}:${local.account_id}:database/*",
      "arn:${local.partition}:glue:${local.region}:${local.account_id}:table/*/*",
      "arn:${local.partition}:glue:${local.region}:${local.account_id}:userDefinedFunction/*/*",
    ]
  }

  dynamic "statement" {
    for_each = var.additional_task_policy_statements
    content {
      sid       = lookup(statement.value, "sid", null)
      effect    = lookup(statement.value, "effect", "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_policy" "task" {
  name   = "${var.name_prefix}-task-policy"
  policy = data.aws_iam_policy_document.task.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

# -------- Execution role (used by ECS agent to pull image, write logs) --------

resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-execution-role" })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_extras" {
  count = length(var.execution_role_kms_key_arns) + length(var.execution_role_secret_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.execution_role_secret_arns) > 0 ? [1] : []
    content {
      sid     = "ReadSecrets"
      effect  = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters",
      ]
      resources = var.execution_role_secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.execution_role_kms_key_arns) > 0 ? [1] : []
    content {
      sid       = "DecryptSecrets"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = var.execution_role_kms_key_arns
    }
  }
}

resource "aws_iam_policy" "execution_extras" {
  count = length(data.aws_iam_policy_document.execution_extras) > 0 ? 1 : 0

  name   = "${var.name_prefix}-execution-extras"
  policy = data.aws_iam_policy_document.execution_extras[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_extras" {
  count = length(aws_iam_policy.execution_extras) > 0 ? 1 : 0

  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_extras[0].arn
}
