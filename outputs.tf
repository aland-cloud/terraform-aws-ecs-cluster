output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ec2_capacity_provider_name" {
  description = "Name of the EC2 capacity provider"
  value       = contains(var.launch_types, "EC2") ? aws_ecs_capacity_provider.ec2[0].name : null
}

output "ec2_capacity_provider_arn" {
  description = "ARN of the EC2 capacity provider"
  value       = contains(var.launch_types, "EC2") ? aws_ecs_capacity_provider.ec2[0].arn : null
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_autoscaling_group.ecs[0].arn : null
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_autoscaling_group.ecs[0].name : null
}

output "launch_template_id" {
  description = "ID of the launch template (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_launch_template.ecs[0].id : null
}

output "launch_template_arn" {
  description = "ARN of the launch template (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_launch_template.ecs[0].arn : null
}

output "ecs_instance_security_group_id" {
  description = "ID of the security group for ECS instances (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_security_group.ecs_instance[0].id : null
}

output "ecs_instance_security_group_arn" {
  description = "ARN of the security group for ECS instances (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_security_group.ecs_instance[0].arn : null
}

output "ecs_instance_role_arn" {
  description = "ARN of the ECS instance IAM role (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_iam_role.ecs_instance_role[0].arn : null
}

output "ecs_instance_role_name" {
  description = "Name of the ECS instance IAM role (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_iam_role.ecs_instance_role[0].name : null
}

output "ecs_instance_profile_arn" {
  description = "ARN of the ECS instance profile (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_iam_instance_profile.ecs_instance_profile[0].arn : null
}

output "ecs_instance_profile_name" {
  description = "Name of the ECS instance profile (EC2 capacity provider only)"
  value       = contains(var.launch_types, "EC2") ? aws_iam_instance_profile.ecs_instance_profile[0].name : null
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role (only when execute command logging is enabled)"
  value       = var.enable_execute_command_logging ? aws_iam_role.ecs_task_execution_role[0].arn : null
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role (only when execute command logging is enabled)"
  value       = var.enable_execute_command_logging ? aws_iam_role.ecs_task_execution_role[0].name : null
}

output "execute_command_log_group_name" {
  description = "Name of the CloudWatch log group for execute command (only when logging is enabled)"
  value       = var.enable_execute_command_logging ? aws_cloudwatch_log_group.ecs_execute_command[0].name : null
}

output "execute_command_log_group_arn" {
  description = "ARN of the CloudWatch log group for execute command (only when logging is enabled)"
  value       = var.enable_execute_command_logging ? aws_cloudwatch_log_group.ecs_execute_command[0].arn : null
}

output "launch_types" {
  description = "Launch types configured for this cluster"
  value       = var.launch_types
}

output "container_insights_enabled" {
  description = "Whether Container Insights is enabled for the cluster"
  value       = var.enable_container_insights
}

output "execute_command_logging_enabled" {
  description = "Whether execute command logging is enabled for the cluster"
  value       = var.enable_execute_command_logging
}
