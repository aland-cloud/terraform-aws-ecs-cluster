resource "aws_ecs_capacity_provider" "ec2" {
  count = contains(var.launch_types, "EC2") ? 1 : 0
  name  = "${var.cluster_name}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.target_capacity_percentage
      minimum_scaling_step_size = var.minimum_scaling_step_size
      maximum_scaling_step_size = var.maximum_scaling_step_size
      instance_warmup_period    = var.instance_warmup_period
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ec2-capacity-provider"
  })

  depends_on = [
    aws_autoscaling_group.ecs
  ]
}
