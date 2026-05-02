output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "availability_zones" {
  description = "AZs used by public subnets."
  value       = aws_subnet.public[*].availability_zone
}

output "internet_gateway_id" {
  description = "Internet gateway ID."
  value       = aws_internet_gateway.this.id
}

output "tasks_security_group_id" {
  description = "Egress-only security group for Fargate tasks."
  value       = aws_security_group.tasks_egress_only.id
}
