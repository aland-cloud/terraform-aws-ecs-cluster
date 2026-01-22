# Terraform AWS ECS Cluster Module

A comprehensive Terraform module for creating Amazon ECS clusters with configurable capacity providers (EC2, Fargate, and Fargate Spot).

## Features

- **Flexible Launch Types**: Support for EC2, Fargate, and Fargate Spot capacity providers
- **Auto Scaling**: Managed scaling with configurable target capacity percentage
- **Security**: Session Manager access (no SSH keys required), security groups, and IAM roles
- **Monitoring**: Optional Container Insights and execute command logging
- **Graceful Scale-in**: Proper instance draining and lifecycle management
- **Cost Optimization**: Configurable capacity provider strategies

## Usage

### Simple Usage (Required Parameters Only)

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345", "subnet-67890"]
}
```

### Basic Usage (Both EC2 and Fargate)

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  cluster_name = "my-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345", "subnet-67890"]
}
```

### Fargate Only

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  cluster_name  = "fargate-cluster"
  vpc_id        = "vpc-12345678"
  launch_types  = ["FARGATE"]
}
```

### EC2 Only

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  cluster_name         = "ec2-cluster"
  vpc_id              = "vpc-12345678"
  subnet_ids          = ["subnet-12345", "subnet-67890"]
  launch_types        = ["EC2"]
  ec2_instance_type   = "t3.large"
  ec2_min_capacity    = 1
  ec2_max_capacity    = 20
  ec2_desired_capacity = 3
}
```

### Complete Configuration (All Parameters)

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  # Basic Configuration
  cluster_name                     = "production-cluster"
  vpc_id                          = "vpc-12345678"
  subnet_ids                      = ["subnet-12345", "subnet-67890"]
  launch_types                    = ["EC2", "FARGATE"]
  
  # CloudWatch and Logging Configuration
  enable_container_insights        = true
  enable_execute_command_logging   = true
  execute_command_log_retention_days = 14
  system_logs_retention_days       = 14
  cloud_init_logs_retention_days   = 14
  
  # Security Group Configuration
  ecs_dynamic_port_range_from      = 32768
  ecs_dynamic_port_range_to        = 65535
  
  # Capacity Provider Strategy Configuration
  fargate_capacity_provider_weight     = 1
  fargate_spot_capacity_provider_weight = 1
  ec2_capacity_provider_weight         = 2
  fargate_capacity_provider_base       = 0
  fargate_spot_capacity_provider_base  = 0
  ec2_capacity_provider_base           = 1
  
  # EC2 Instance Configuration
  ec2_instance_type                   = "t3.large"
  ec2_min_capacity                    = 2
  ec2_max_capacity                    = 50
  ec2_desired_capacity                = 5
  metadata_http_put_response_hop_limit = 2
  
  # Auto Scaling Configuration
  target_capacity_percentage                   = 85
  asg_health_check_grace_period               = 300
  asg_instance_refresh_min_healthy_percentage = 50
  instance_warmup_period                      = 300
  lifecycle_hook_heartbeat_timeout            = 900
  
  # Capacity Provider Scaling Configuration
  minimum_scaling_step_size = 1
  maximum_scaling_step_size = 100
  
  # Additional Configuration
  additional_security_groups = ["sg-additional-12345"]
  
  # Tags
  tags = {
    Environment = "production"
    Team        = "platform"
    Project     = "ecs-infrastructure"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

### Basic Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | `"ecs-cluster"` | no |
| vpc_id | VPC ID where the ECS cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the Auto Scaling Group (required when EC2 launch type is enabled) | `list(string)` | `[]` | no |
| launch_types | List of launch types for capacity providers. Valid values: EC2, FARGATE | `list(string)` | `["EC2", "FARGATE"]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

### CloudWatch and Logging Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_container_insights | Enable CloudWatch Container Insights for the cluster | `bool` | `false` | no |
| enable_execute_command_logging | Enable execute command logging to CloudWatch | `bool` | `false` | no |
| execute_command_log_retention_days | Number of days to retain execute command logs in CloudWatch | `number` | `7` | no |
| system_logs_retention_days | Number of days to retain system logs for instance id | `number` | `7` | no |
| cloud_init_logs_retention_days | Number of days to retain cloud-init logs in CloudWatch | `number` | `7` | no |

### Security Group Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ecs_dynamic_port_range_from | Starting port for ECS dynamic port range | `number` | `32768` | no |
| ecs_dynamic_port_range_to | Ending port for ECS dynamic port range | `number` | `65535` | no |

### Capacity Provider Strategy Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| fargate_capacity_provider_weight | Weight for FARGATE capacity provider in default strategy | `number` | `1` | no |
| fargate_spot_capacity_provider_weight | Weight for FARGATE_SPOT capacity provider in default strategy | `number` | `1` | no |
| ec2_capacity_provider_weight | Weight for EC2 capacity provider in default strategy | `number` | `2` | no |
| fargate_capacity_provider_base | Base number of tasks for FARGATE capacity provider | `number` | `0` | no |
| fargate_spot_capacity_provider_base | Base number of tasks for FARGATE_SPOT capacity provider | `number` | `0` | no |
| ec2_capacity_provider_base | Base number of tasks for EC2 capacity provider | `number` | `1` | no |

### EC2 Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ec2_instance_type | Instance type for EC2 capacity provider | `string` | `"t3.medium"` | no |
| ec2_min_capacity | Minimum number of EC2 instances in the Auto Scaling Group | `number` | `1` | no |
| ec2_max_capacity | Maximum number of EC2 instances in the Auto Scaling Group | `number` | `10` | no |
| ec2_desired_capacity | Desired number of EC2 instances in the Auto Scaling Group | `number` | `2` | no |
| additional_security_groups | Additional security group IDs to attach to EC2 instances | `list(string)` | `[]` | no |
| metadata_http_put_response_hop_limit | Number of hops allowed for metadata token requests | `number` | `2` | no |

### Auto Scaling Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| target_capacity_percentage | Target capacity percentage for managed scaling | `number` | `90` | no |
| asg_health_check_grace_period | Time (in seconds) after instance comes into service before checking health | `number` | `300` | no |
| asg_instance_refresh_min_healthy_percentage | Minimum percentage of instances that must remain healthy during instance refresh | `number` | `50` | no |
| instance_warmup_period | Time (in seconds) for instance warmup period | `number` | `300` | no |
| lifecycle_hook_heartbeat_timeout | Maximum time (in seconds) that can elapse before lifecycle action times out | `number` | `900` | no |

### Capacity Provider Scaling Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| minimum_scaling_step_size | Minimum number of instances to scale up or down at a time | `number` | `1` | no |
| maximum_scaling_step_size | Maximum number of instances to scale up or down at a time | `number` | `100` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| ec2_capacity_provider_name | Name of the EC2 capacity provider |
| ec2_capacity_provider_arn | ARN of the EC2 capacity provider |
| capacity_providers | List of capacity providers associated with the cluster |
| autoscaling_group_arn | ARN of the Auto Scaling Group (EC2 capacity provider only) |
| autoscaling_group_name | Name of the Auto Scaling Group (EC2 capacity provider only) |
| launch_template_id | ID of the launch template (EC2 capacity provider only) |
| ecs_instance_security_group_id | ID of the security group for ECS instances (EC2 capacity provider only) |
| ecs_instance_role_arn | ARN of the ECS instance IAM role (EC2 capacity provider only) |
| ecs_task_execution_role_arn | ARN of the ECS task execution role (only when execute command logging is enabled) |
| execute_command_log_group_name | Name of the CloudWatch log group for execute command (only when logging is enabled) |
| launch_types | Launch types configured for this cluster |
| container_insights_enabled | Whether Container Insights is enabled for the cluster |
| execute_command_logging_enabled | Whether execute command logging is enabled for the cluster |

## Capacity Provider Strategy

This module configures a default capacity provider strategy with customizable weights and base values:

**Default Configuration:**
- **FARGATE**: Weight = 1, Base = 0
- **FARGATE_SPOT**: Weight = 1, Base = 0  
- **EC2**: Weight = 2, Base = 1

**Strategy Behavior:**
- **Base**: Minimum number of tasks that will use the specified capacity provider
- **Weight**: Relative proportion of tasks beyond the base that will use the capacity provider
- Higher weights mean more tasks will be scheduled on that capacity provider

You can customize these values using the capacity provider strategy variables to optimize for your specific cost and performance requirements.

## Security

- **No SSH Keys**: Uses AWS Session Manager for secure instance access
- **IAM Roles**: Proper IAM roles with least privilege access
- **Security Groups**: Configured for ECS task communication
- **Instance Metadata**: IMDSv2 required for enhanced security

## Monitoring and Logging

- **Container Insights**: Optional CloudWatch Container Insights for cluster-level metrics
- **Execute Command Logging**: Optional logging of ECS execute commands to CloudWatch with configurable retention
- **Instance Logs**: EC2 instances automatically send system logs and cloud-init logs to dedicated CloudWatch log groups (`/ecs/ec2/system` and `/ecs/ec2/cloud-init`) with configurable retention periods

## License

This module is released under the MIT License. See LICENSE for more details.
