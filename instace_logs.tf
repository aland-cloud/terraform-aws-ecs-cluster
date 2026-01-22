resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/ecs/ec2/system"
  retention_in_days = var.system_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-system-logs"
  })
}

resource "aws_cloudwatch_log_group" "cloud_init_logs" {
  name              = "/ecs/ec2/cloud-init"
  retention_in_days = var.cloud_init_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cloud-logs"
  })
}
