output "asg_arn" {
  description = "Auto Scaling Group ARN."
  value       = aws_autoscaling_group.this.arn
}

output "asg_name" {
  description = "Auto Scaling Group name."
  value       = aws_autoscaling_group.this.name
}

output "instance_role_arn" {
  description = "IAM role ARN used by EC2 instances."
  value       = aws_iam_role.instance.arn
}

output "instance_role_name" {
  description = "IAM role name used by EC2 instances."
  value       = aws_iam_role.instance.name
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = aws_launch_template.this.id
}
