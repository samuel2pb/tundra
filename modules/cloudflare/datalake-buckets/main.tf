locals {
  zones = toset(var.zones)
}

resource "cloudflare_r2_bucket" "this" {
  for_each = local.zones

  account_id    = var.account_id
  name          = "${var.name_prefix}-${each.key}"
  location      = var.location
  jurisdiction  = var.jurisdiction
  storage_class = var.storage_class
}

resource "cloudflare_r2_bucket_lifecycle" "default" {
  for_each = cloudflare_r2_bucket.this

  account_id   = var.account_id
  bucket_name  = each.value.name
  jurisdiction = var.jurisdiction

  rules = concat(
    [{
      id      = "abort-incomplete-multipart"
      enabled = true
      conditions = {
        prefix = ""
      }
      abort_multipart_uploads_transition = {
        condition = {
          max_age = var.abort_incomplete_multipart_upload_days * 86400
          type    = "Age"
        }
      }
    }],
    [for rule in var.lifecycle_rules : {
      id      = rule.id
      enabled = rule.enabled
      conditions = {
        prefix = rule.prefix
      }
      delete_objects_transition = rule.delete_after_days != null ? {
        condition = {
          max_age = rule.delete_after_days * 86400
          type    = "Age"
        }
      } : null
      storage_class_transitions = rule.transition_to_ia_after_days != null ? [{
        condition = {
          max_age = rule.transition_to_ia_after_days * 86400
          type    = "Age"
        }
        storage_class = "InfrequentAccess"
      }] : []
    }]
  )
}

resource "cloudflare_r2_bucket_cors" "this" {
  for_each = length(var.cors_allowed_origins) > 0 ? cloudflare_r2_bucket.this : {}

  account_id   = var.account_id
  bucket_name  = each.value.name
  jurisdiction = var.jurisdiction

  rules = [{
    id = "datalake-cors"
    allowed = {
      methods = var.cors_allowed_methods
      origins = var.cors_allowed_origins
      headers = ["*"]
    }
    expose_headers  = ["ETag", "Content-Length", "Content-Range"]
    max_age_seconds = 3600
  }]
}

resource "cloudflare_r2_managed_domain" "this" {
  for_each = var.enable_managed_domain ? cloudflare_r2_bucket.this : {}

  account_id   = var.account_id
  bucket_name  = each.value.name
  jurisdiction = var.jurisdiction
  enabled      = true
}
