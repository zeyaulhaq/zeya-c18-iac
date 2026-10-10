############################################################
# ECS cluster (Fargate = serverless containers, no EC2 to manage)
############################################################
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-c18-cluster"
}

############################################################
# CloudWatch log groups (one per service)
############################################################
resource "aws_cloudwatch_log_group" "s3_app" {
  name              = "/ecs/${var.name_prefix}-flask-s3-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "sqs_app" {
  name              = "/ecs/${var.name_prefix}-flask-sqs-service"
  retention_in_days = 7
}

############################################################
# SERVICE 1: Flask app -> S3   (port 5001)
############################################################
resource "aws_ecs_task_definition" "s3_app" {
  family                   = "${var.name_prefix}-flask-s3-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.s3_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "flask-s3-service"
    image     = "${aws_ecr_repository.s3_app.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 5001
      protocol      = "tcp"
    }]

    # These are the env vars app.py reads with os.environ[...]
    environment = [
      { name = "AWS_REGION", value = var.aws_region },
      { name = "BUCKET_NAME", value = aws_s3_bucket.uploads.bucket }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.s3_app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "s3_app" {
  name            = "${var.name_prefix}-flask-s3-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.s3_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # needed to pull from ECR and to reach the app without a load balancer
  }
}

############################################################
# SERVICE 2: Flask app -> SQS   (port 5002)
############################################################
resource "aws_ecs_task_definition" "sqs_app" {
  family                   = "${var.name_prefix}-flask-sqs-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.sqs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "flask-sqs-service"
    image     = "${aws_ecr_repository.sqs_app.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 5002
      protocol      = "tcp"
    }]

    environment = [
      { name = "AWS_REGION", value = var.aws_region },
      { name = "QUEUE_URL", value = aws_sqs_queue.messages.url }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.sqs_app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "sqs_app" {
  name            = "${var.name_prefix}-flask-sqs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.sqs_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }
}