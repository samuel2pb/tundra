locals {
  defaults_by_purpose = {
    tfstate = {
      versioning                 = true
      expiration_days            = 0
      noncurrent_expiration_days = 365
    }
    logs = {
      versioning                 = false
      expiration_days            = 90
      noncurrent_expiration_days = 0
    }
    artifacts = {
      versioning                 = true
      expiration_days            = 0
      noncurrent_expiration_days = 30
    }
    athena = {
      versioning                 = false
      expiration_days            = 14
      noncurrent_expiration_days = 0
    }
  }

  defaults = local.defaults_by_purpose[var.purpose]

  versioning_enabled         = var.versioning_override == null ? local.defaults.versioning : var.versioning_override
  expiration_days            = var.expiration_days_override == null ? local.defaults.expiration_days : var.expiration_days_override
  noncurrent_expiration_days = var.noncurrent_expiration_days_override == null ? local.defaults.noncurrent_expiration_days : var.noncurrent_expiration_days_override

  is_tfstate              = var.purpose == "tfstate"
  effective_force_destroy = local.is_tfstate ? false : var.force_destroy
}

resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = local.effective_force_destroy

  tags = merge(var.tags, {
    Name    = var.name
    purpose = var.purpose
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = local.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  dynamic "rule" {
    for_each = local.expiration_days > 0 ? [1] : []
    content {
      id     = "expire-current"
      status = "Enabled"

      filter {}

      expiration {
        days = local.expiration_days
      }
    }
  }

  dynamic "rule" {
    for_each = local.noncurrent_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-noncurrent"
      status = "Enabled"

      filter {}

      noncurrent_version_expiration {
        noncurrent_days = local.noncurrent_expiration_days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# Deny-unencrypted-transport policy on every bucket; deny-unencrypted-uploads on tfstate.
data "aws_iam_policy_document" "this" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = local.is_tfstate ? [1] : []
    content {
      sid       = "DenyUnencryptedPuts"
      effect    = "Deny"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "StringNotEquals"
        variable = "s3:x-amz-server-side-encryption"
        values   = var.kms_key_arn == null ? ["AES256"] : ["aws:kms"]
      }
    }
  }

  # Logs bucket: allow AWS log-delivery service principal to write.
  dynamic "statement" {
    for_each = var.purpose == "logs" ? [1] : []
    content {
      sid       = "AllowLogDeliveryWrite"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/*"]

      principals {
        type        = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }

      dynamic "condition" {
        for_each = length(var.log_delivery_source_account_ids) > 0 ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = var.log_delivery_source_account_ids
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.purpose == "logs" ? [1] : []
    content {
      sid       = "AllowLogDeliveryAclCheck"
      effect    = "Allow"
      actions   = ["s3:GetBucketAcl"]
      resources = [aws_s3_bucket.this.arn]

      principals {
        type        = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
