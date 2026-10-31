data "aws_ssm_parameter" "ecs_optimized_ami" {
  count = contains(var.launch_types, "EC2") ? 1 : 0

  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}
