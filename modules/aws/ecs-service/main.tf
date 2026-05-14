resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  deployment_circuit_breaker {
    enable   = var.enable_circuit_breaker
    rollback = var.enable_circuit_breaker
  }

  force_new_deployment  = var.force_new_deployment
  wait_for_steady_state = var.wait_for_steady_state

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [desired_count]
  }
}
