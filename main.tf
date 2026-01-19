resource "aws_cloudwatch_log_group" "ecs_execute_command" {
  count             = var.enable_execute_command_logging ? 1 : 0
  name              = "/ecs/execute-command/${var.cluster_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-execute-command-logs"
  })
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  dynamic "configuration" {
    for_each = var.enable_execute_command_logging ? [1] : []
    content {
      execute_command_configuration {
        logging = "OVERRIDE"
        log_configuration {
          cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_execute_command[0].name
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

resource "aws_security_group" "ecs_instance" {
  count       = contains(var.launch_types, "EC2") ? 1 : 0
  name        = "${var.cluster_name}-ecs-instance-sg"
  description = "Security group for ECS EC2 instances in ${var.cluster_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow dynamic port range for ECS tasks"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instance-sg"
  })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = compact([
    contains(var.launch_types, "FARGATE") ? "FARGATE" : "",
    contains(var.launch_types, "FARGATE") ? "FARGATE_SPOT" : "",
    contains(var.launch_types, "EC2") ? aws_ecs_capacity_provider.ec2[0].name : ""
  ])

  dynamic "default_capacity_provider_strategy" {
    for_each = contains(var.launch_types, "FARGATE") ? [1] : []
    content {
      capacity_provider = "FARGATE"
      weight            = contains(var.launch_types, "EC2") ? 1 : 2
      base              = 0
    }
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = contains(var.launch_types, "FARGATE") ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = contains(var.launch_types, "EC2") ? [1] : []
    content {
      capacity_provider = aws_ecs_capacity_provider.ec2[0].name
      weight            = contains(var.launch_types, "FARGATE") ? 2 : 1
      base              = 1
    }
  }

  depends_on = [
    aws_ecs_capacity_provider.ec2
  ]
}
