resource "aws_cloudwatch_log_group" "ecs_execute_command" {
  count             = var.enable_execute_command_logging ? 1 : 0
  name              = "/ecs/execute-command/${var.cluster_name}"
  retention_in_days = var.execute_command_log_retention_days

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

  depends_on = [aws_cloudwatch_log_group.system_logs, aws_cloudwatch_log_group.cloud_init_logs]
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
    from_port   = var.ecs_dynamic_port_range_from
    to_port     = var.ecs_dynamic_port_range_to
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow dynamic port range for ECS tasks"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instance-sg"
  })
}

# Fargate Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  count        = contains(var.launch_types, "FARGATE") ? 1 : 0
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = var.fargate_capacity_provider_weight
    base              = var.fargate_capacity_provider_base
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = var.fargate_spot_capacity_provider_weight
    base              = var.fargate_spot_capacity_provider_base
  }
}

resource "aws_ecs_cluster_capacity_providers" "ec2" {
  count        = contains(var.launch_types, "EC2") ? 1 : 0
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.ec2[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2[0].name
    weight            = var.ec2_capacity_provider_weight
    base              = var.ec2_capacity_provider_base
  }

  depends_on = [
    aws_ecs_capacity_provider.ec2
  ]
}
