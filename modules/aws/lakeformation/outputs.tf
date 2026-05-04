output "registered_resource_arns" {
  description = "Map of zone/purpose => S3 ARN registered as a Lake Formation data location."
  value       = { for k, r in aws_lakeformation_resource.this : k => r.arn }
}
