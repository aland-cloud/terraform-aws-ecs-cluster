resource "aws_iam_role" "ecs_instance_role" {
  count = contains(var.launch_types, "EC2") ? 1 : 0
  name  = "${var.cluster_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instance-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  count      = contains(var.launch_types, "EC2") ? 1 : 0
  role       = aws_iam_role.ecs_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm_policy" {
  count      = contains(var.launch_types, "EC2") ? 1 : 0
  role       = aws_iam_role.ecs_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  count = contains(var.launch_types, "EC2") ? 1 : 0
  name  = "${var.cluster_name}-ecs-instance-profile"
  role  = aws_iam_role.ecs_instance_role[0].name

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instance-profile"
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.enable_execute_command_logging ? 1 : 0
  name  = "${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  count      = var.enable_execute_command_logging ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execute_command_policy" {
  count = var.enable_execute_command_logging ? 1 : 0
  name  = "${var.cluster_name}-execute-command-policy"
  role  = aws_iam_role.ecs_task_execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/ecs/execute-command/*"
      }
    ]
  })
}
