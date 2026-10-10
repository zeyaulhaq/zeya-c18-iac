# Find the class VPC by its Name tag
data "aws_vpc" "class" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Find the PUBLIC subnets in that VPC (names like sctp-vpc-ce13-public-us-east-1a)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.class.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-public-*"]
  }
}

# Firewall for both ECS services
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-c18-ecs-tasks-sg"
  description = "Allow inbound to Flask S3 (5001) and SQS (5002) services"
  vpc_id      = data.aws_vpc.class.id

  ingress {
    description = "Flask S3 service"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask SQS service"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound (ECR pulls, S3, SQS, CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}