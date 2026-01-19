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

### Advanced Configuration

```hcl
module "ecs_cluster" {
  source = "./terraform-aws-ecs-cluster"

  cluster_name                   = "advanced-cluster"
  vpc_id                        = "vpc-12345678"
  subnet_ids                    = ["subnet-12345", "subnet-67890"]
  
  # Capacity configuration
  launch_types                  = ["EC2", "FARGATE"]
  target_capacity_percentage    = 85
  
  # EC2 configuration
  ec2_instance_type            = "t3.large"
  ec2_min_capacity             = 2
  ec2_max_capacity             = 50
  ec2_desired_capacity         = 5
  
  # Monitoring and logging
  enable_container_insights     = true
  enable_execute_command_logging = true
  
  # Additional security groups
  additional_security_groups    = ["sg-additional"]
  
  # Tags
  tags = {
    Environment = "production"
    Team        = "platform"
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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | `"ecs-cluster"` | no |
| vpc_id | VPC ID where the ECS cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the Auto Scaling Group (only required when EC2 launch type is enabled) | `list(string)` | `[]` | no |
| launch_types | List of launch types for capacity providers. Valid values: EC2, FARGATE | `list(string)` | `["EC2", "FARGATE"]` | no |
| enable_container_insights | Enable CloudWatch Container Insights for the cluster | `bool` | `false` | no |
| enable_execute_command_logging | Enable execute command logging to CloudWatch | `bool` | `false` | no |
| target_capacity_percentage | Target capacity percentage for managed scaling | `number` | `90` | no |
| ec2_instance_type | Instance type for EC2 capacity provider | `string` | `"t3.medium"` | no |
| ec2_min_capacity | Minimum number of EC2 instances in the Auto Scaling Group | `number` | `1` | no |
| ec2_max_capacity | Maximum number of EC2 instances in the Auto Scaling Group | `number` | `10` | no |
| ec2_desired_capacity | Desired number of EC2 instances in the Auto Scaling Group | `number` | `2` | no |
| additional_security_groups | Additional security group IDs to attach to EC2 instances | `list(string)` | `[]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

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

This module configures a default capacity provider strategy:

- **Fargate + EC2**: When both are enabled, EC2 gets higher weight (2) with base capacity (1), while Fargate and Fargate Spot get weight (1)
- **Fargate Only**: Fargate gets weight (2), Fargate Spot gets weight (1)
- **EC2 Only**: EC2 gets weight (1) with base capacity (1)

## Security

- **No SSH Keys**: Uses AWS Session Manager for secure instance access
- **IAM Roles**: Proper IAM roles with least privilege access
- **Security Groups**: Configured for ECS task communication
- **Instance Metadata**: IMDSv2 required for enhanced security

## Monitoring and Logging

- **Container Insights**: Optional CloudWatch Container Insights for cluster-level metrics
- **Execute Command Logging**: Optional logging of ECS execute commands to CloudWatch
- **Instance Logs**: EC2 instances send system and ECS agent logs to CloudWatch

## License

This module is released under the MIT License. See LICENSE for more details.
