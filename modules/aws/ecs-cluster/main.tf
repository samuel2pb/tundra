resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ecs_capacity_provider" "ec2" {
  for_each = { for cp in var.ec2_capacity_providers : cp.name => cp }

  name = each.value.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = each.value.asg_arn
    managed_termination_protection = each.value.managed_termination_protection ? "ENABLED" : "DISABLED"

    managed_scaling {
      status                    = each.value.managed_scaling ? "ENABLED" : "DISABLED"
      target_capacity           = each.value.target_capacity
      minimum_scaling_step_size = each.value.minimum_scaling_step_size
      maximum_scaling_step_size = each.value.maximum_scaling_step_size
    }
  }

  tags = merge(var.tags, { Name = each.value.name })
}

locals {
  ec2_provider_names = [for cp in aws_ecs_capacity_provider.ec2 : cp.name]
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = concat(
    ["FARGATE", "FARGATE_SPOT"],
    local.ec2_provider_names,
  )

  default_capacity_provider_strategy {
    capacity_provider = var.default_capacity_provider
    weight            = 1
    base              = 0
  }
}
