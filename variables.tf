variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}

variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group (required when EC2 launch type is enabled)"
  type        = list(string)
  default     = []
  
  validation {
    condition     = !contains(var.launch_types, "EC2") || length(var.subnet_ids) > 0
    error_message = "subnet_ids must be provided when EC2 launch type is enabled."
  }
}

variable "launch_types" {
  description = "List of launch types for capacity providers. Valid values: EC2, FARGATE"
  type        = list(string)
  default     = ["EC2", "FARGATE"]
  
  validation {
    condition = length(var.launch_types) > 0 && alltrue([
      for launch_type in var.launch_types : contains(["EC2", "FARGATE"], launch_type)
    ])
    error_message = "Launch types must be a non-empty list containing only 'EC2' and/or 'FARGATE'."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false
}

variable "enable_execute_command_logging" {
  description = "Enable execute command logging to CloudWatch"
  type        = bool
  default     = false
}

variable "target_capacity_percentage" {
  description = "Target capacity percentage for managed scaling"
  type        = number
  default     = 90
  
  validation {
    condition     = var.target_capacity_percentage > 0 && var.target_capacity_percentage <= 100
    error_message = "Target capacity percentage must be between 1 and 100."
  }
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 capacity provider"
  type        = string
  default     = "t3.medium"
}

variable "ec2_min_capacity" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "ec2_max_capacity" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 10
}

variable "ec2_desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "additional_security_groups" {
  description = "Additional security group IDs to attach to EC2 instances"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
