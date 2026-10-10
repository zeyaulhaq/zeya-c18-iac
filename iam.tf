############################################################
# 1. Task EXECUTION role (used by ECS itself):
#    pull images from ECR + write logs to CloudWatch
############################################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-c18-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################################
# 2. TASK role for Service 1 (used by YOUR app code via boto3):
#    only allowed to put objects into the uploads bucket
############################################################
resource "aws_iam_role" "s3_task" {
  name = "${var.name_prefix}-c18-s3-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_task" {
  name = "allow-put-to-uploads-bucket"
  role = aws_iam_role.s3_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

############################################################
# 3. TASK role for Service 2: only allowed to send to the queue
############################################################
resource "aws_iam_role" "sqs_task" {
  name = "${var.name_prefix}-c18-sqs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sqs_task" {
  name = "allow-send-to-messages-queue"
  role = aws_iam_role.sqs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage", "sqs:GetQueueUrl"]
      Resource = aws_sqs_queue.messages.arn
    }]
  })
}

############################################################
# 4. GitHub Actions role for the APP repo (OIDC, no access keys):
#    push images to the 2 ECR repos + redeploy the 2 ECS services
############################################################
# The OIDC provider already exists in the class account - just look it up
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_app_deploy" {
  name = "${var.name_prefix}-c18-github-app-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # only workflows in YOUR app repo can assume this role
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_app_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_app_deploy" {
  name = "ecr-push-and-ecs-deploy"
  role = aws_iam_role.github_app_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          aws_ecr_repository.s3_app.arn,
          aws_ecr_repository.sqs_app.arn
        ]
      },
      {
        Sid      = "EcsDeploy"
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.this.name}/*"
      }
    ]
  })
}