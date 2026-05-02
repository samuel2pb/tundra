locals {
  container_name = coalesce(var.container_name, var.family)
  log_group_name = coalesce(var.log_group_name, "/ecs/${var.family}")

  container_definition = merge(
    {
      name      = local.container_name
      image     = var.image
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = local.container_name
        }
      }
    },
    length(var.command) > 0 ? { command = var.command } : {},
    length(var.entrypoint) > 0 ? { entryPoint = var.entrypoint } : {},
    length(var.environment) > 0 ? { environment = var.environment } : {},
    length(var.secrets) > 0 ? { secrets = var.secrets } : {},
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = local.log_group_name })
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn

  runtime_platform {
    operating_system_family = var.runtime_platform.operating_system_family
    cpu_architecture        = var.runtime_platform.cpu_architecture
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_gib > 0 ? [1] : []
    content {
      size_in_gib = var.ephemeral_storage_gib
    }
  }

  container_definitions = jsonencode([local.container_definition])

  tags = merge(var.tags, { Name = var.family })

  depends_on = [aws_cloudwatch_log_group.this]
}
