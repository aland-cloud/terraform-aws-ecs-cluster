resource "aws_launch_template" "ecs" {
  count       = contains(var.launch_types, "EC2") ? 1 : 0
  name        = "${var.cluster_name}-ecs-launch-template"
  description = "Launch template for ECS EC2 instances in ${var.cluster_name}"

  image_id      = data.aws_ami.ecs_optimized[0].id
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = concat(
    [aws_security_group.ecs_instance[0].id],
    var.additional_security_groups
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile[0].name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-ecs-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags   = merge(var.tags, {
      Name = "${var.cluster_name}-ecs-volume"
    })
  }

  monitoring {
    enabled = true
  }

  ebs_optimized = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-launch-template"
  })
}

resource "aws_autoscaling_group" "ecs" {
  count               = contains(var.launch_types, "EC2") ? 1 : 0
  name                = "${var.cluster_name}-ecs-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = []
  health_check_type   = "ECS"
  health_check_grace_period = 300

  min_size         = var.ec2_min_capacity
  max_size         = var.ec2_max_capacity
  desired_capacity = var.ec2_desired_capacity

  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = "$Latest"
  }

  capacity_rebalance = true

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [
    aws_launch_template.ecs
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_lifecycle_hook" "ecs_instance_terminating" {
  count                  = contains(var.launch_types, "EC2") ? 1 : 0
  name                   = "${var.cluster_name}-ecs-terminating-hook"
  autoscaling_group_name = aws_autoscaling_group.ecs[0].name
  default_result         = "ABANDON"
  heartbeat_timeout      = 900
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"

  notification_metadata = jsonencode({
    cluster = var.cluster_name
  })
}
