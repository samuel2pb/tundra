data "aws_partition" "current" {}
data "aws_region" "current" {}

# ── AMI lookup ───────────────────────────────────────────────────────────────

data "aws_ssm_parameter" "bottlerocket_ami" {
  count = var.ami_type == "bottlerocket" ? 1 : 0
  name  = "/aws/service/bottlerocket/aws-ecs-2/${var.ami_architecture}/latest/image_id"
}

data "aws_ssm_parameter" "al2023_ami" {
  count = var.ami_type == "al2023" ? 1 : 0
  name  = "/aws/service/ecs/optimized-ami/amazon-linux-2023/${var.ami_architecture == "arm64" ? "arm64" : "recommended"}/image_id"
}

locals {
  ami_id = var.ami_type == "bottlerocket" ? data.aws_ssm_parameter.bottlerocket_ami[0].value : data.aws_ssm_parameter.al2023_ami[0].value

  bottlerocket_user_data = <<-TOML
    [settings.ecs]
    cluster = "${var.cluster_name}"

    [settings.ecs.instance-attributes]
    managed-by = "tundra"
  TOML

  al2023_user_data = <<-BASH
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
  BASH

  user_data = base64encode(
    var.ami_type == "bottlerocket" ? local.bottlerocket_user_data : local.al2023_user_data
  )
}

# ── IAM instance profile ────────────────────────────────────────────────────

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = merge(var.tags, { Name = "${var.name}-instance-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.instance.name
  tags = var.tags
}

# ── Launch template ──────────────────────────────────────────────────────────

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = local.ami_id
  user_data     = local.user_data

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  block_device_mappings {
    device_name = var.ami_type == "bottlerocket" ? "/dev/xvdb" : "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-ecs" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name}-ecs" })
  }

  tags = merge(var.tags, { Name = "${var.name}-lt" })

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ───────────────────────────────────────────────────────

resource "aws_autoscaling_group" "this" {
  name_prefix         = "${var.name}-"
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  # Let ECS managed scaling handle capacity, protect from scale-in
  protect_from_scale_in = true

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage
      spot_allocation_strategy                 = var.spot_allocation_strategy
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name                 = "${var.name}-ecs"
      AmazonECSManaged     = "true"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
