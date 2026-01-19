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

# CloudWatch and Logging Configuration
variable "execute_command_log_retention_days" {
  description = "Number of days to retain execute command logs in CloudWatch"
  type        = number
  default     = 7
  
  validation {
    condition     = var.execute_command_log_retention_days > 0
    error_message = "Log retention days must be greater than 0."
  }
}


# Security Group Configuration
variable "ecs_dynamic_port_range_from" {
  description = "Starting port for ECS dynamic port range"
  type        = number
  default     = 32768
  
  validation {
    condition     = var.ecs_dynamic_port_range_from >= 1024 && var.ecs_dynamic_port_range_from <= 65535
    error_message = "Dynamic port range from must be between 1024 and 65535."
  }
}

variable "ecs_dynamic_port_range_to" {
  description = "Ending port for ECS dynamic port range"
  type        = number
  default     = 65535
  
  validation {
    condition     = var.ecs_dynamic_port_range_to >= 1024 && var.ecs_dynamic_port_range_to <= 65535
    error_message = "Dynamic port range to must be between 1024 and 65535."
  }
}

# Capacity Provider Strategy Configuration
variable "fargate_capacity_provider_weight" {
  description = "Weight for FARGATE capacity provider in default strategy"
  type        = number
  default     = 100
  
  validation {
    condition     = var.fargate_capacity_provider_weight >= 0
    error_message = "FARGATE capacity provider weight must be non-negative."
  }
}

variable "fargate_spot_capacity_provider_weight" {
  description = "Weight for FARGATE_SPOT capacity provider in default strategy"
  type        = number
  default     = 100
  
  validation {
    condition     = var.fargate_spot_capacity_provider_weight >= 0
    error_message = "FARGATE_SPOT capacity provider weight must be non-negative."
  }
}

variable "ec2_capacity_provider_weight" {
  description = "Weight for EC2 capacity provider in default strategy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.ec2_capacity_provider_weight >= 0
    error_message = "EC2 capacity provider weight must be non-negative."
  }
}

variable "fargate_capacity_provider_base" {
  description = "Base number of tasks for FARGATE capacity provider"
  type        = number
  default     = 0
  
  validation {
    condition     = var.fargate_capacity_provider_base >= 0
    error_message = "FARGATE capacity provider base must be non-negative."
  }
}

variable "fargate_spot_capacity_provider_base" {
  description = "Base number of tasks for FARGATE_SPOT capacity provider"
  type        = number
  default     = 0
  
  validation {
    condition     = var.fargate_spot_capacity_provider_base >= 0
    error_message = "FARGATE_SPOT capacity provider base must be non-negative."
  }
}

variable "ec2_capacity_provider_base" {
  description = "Base number of tasks for EC2 capacity provider"
  type        = number
  default     = 1
  
  validation {
    condition     = var.ec2_capacity_provider_base >= 0
    error_message = "EC2 capacity provider base must be non-negative."
  }
}

# Auto Scaling Configuration
variable "asg_health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_health_check_grace_period >= 0
    error_message = "Health check grace period must be non-negative."
  }
}

variable "asg_instance_refresh_min_healthy_percentage" {
  description = "Minimum percentage of instances that must remain healthy during instance refresh"
  type        = number
  default     = 50
  
  validation {
    condition     = var.asg_instance_refresh_min_healthy_percentage >= 0 && var.asg_instance_refresh_min_healthy_percentage <= 100
    error_message = "Instance refresh min healthy percentage must be between 0 and 100."
  }
}

variable "instance_warmup_period" {
  description = "Time (in seconds) for instance warmup period"
  type        = number
  default     = 300
  
  validation {
    condition     = var.instance_warmup_period >= 0
    error_message = "Instance warmup period must be non-negative."
  }
}

variable "lifecycle_hook_heartbeat_timeout" {
  description = "Maximum time (in seconds) that can elapse before lifecycle action times out"
  type        = number
  default     = 900
  
  validation {
    condition     = var.lifecycle_hook_heartbeat_timeout >= 30 && var.lifecycle_hook_heartbeat_timeout <= 7200
    error_message = "Lifecycle hook heartbeat timeout must be between 30 and 7200 seconds."
  }
}

# EC2 Instance Configuration
variable "metadata_http_put_response_hop_limit" {
  description = "Number of hops allowed for metadata token requests"
  type        = number
  default     = 2
  
  validation {
    condition     = var.metadata_http_put_response_hop_limit >= 1 && var.metadata_http_put_response_hop_limit <= 64
    error_message = "Metadata HTTP PUT response hop limit must be between 1 and 64."
  }
}

# Capacity Provider Scaling Configuration
variable "minimum_scaling_step_size" {
  description = "Minimum number of instances to scale up or down at a time"
  type        = number
  default     = 1
  
  validation {
    condition     = var.minimum_scaling_step_size >= 1
    error_message = "Minimum scaling step size must be at least 1."
  }
}

variable "maximum_scaling_step_size" {
  description = "Maximum number of instances to scale up or down at a time"
  type        = number
  default     = 100
  
  validation {
    condition     = var.maximum_scaling_step_size >= 1
    error_message = "Maximum scaling step size must be at least 1."
  }
}
