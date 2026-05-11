output "bucket_names" {
  description = "Map of zone => bucket name."
  value       = { for k, b in cloudflare_r2_bucket.this : k => b.name }
}

output "bucket_ids" {
  description = "Map of zone => bucket id."
  value       = { for k, b in cloudflare_r2_bucket.this : k => b.id }
}

output "bucket_creation_dates" {
  description = "Map of zone => bucket creation timestamp."
  value       = { for k, b in cloudflare_r2_bucket.this : k => b.creation_date }
}

output "bucket_s3_endpoints" {
  description = "Map of zone => S3-compatible endpoint URL."
  value       = { for k, b in cloudflare_r2_bucket.this : k => "https://${var.account_id}.r2.cloudflarestorage.com/${b.name}" }
}

output "managed_domain_urls" {
  description = "Map of zone => public r2.dev URL (only populated when enable_managed_domain = true)."
  value       = { for k, d in cloudflare_r2_managed_domain.this : k => "https://${d.domain}" }
}
