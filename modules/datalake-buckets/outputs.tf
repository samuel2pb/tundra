output "bucket_ids" {
  description = "Map of zone => bucket id."
  value       = { for k, b in aws_s3_bucket.this : k => b.id }
}

output "bucket_arns" {
  description = "Map of zone => bucket ARN."
  value       = { for k, b in aws_s3_bucket.this : k => b.arn }
}

output "bucket_domain_names" {
  description = "Map of zone => bucket regional domain name."
  value       = { for k, b in aws_s3_bucket.this : k => b.bucket_regional_domain_name }
}
