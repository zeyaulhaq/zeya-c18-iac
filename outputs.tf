# Copy these values into the APP repo's GitHub Actions variables
output "AWS_REGION" {
  value = var.aws_region
}

output "AWS_DEPLOY_ROLE_ARN" {
  value = aws_iam_role.github_app_deploy.arn
}

output "ECS_CLUSTER" {
  value = aws_ecs_cluster.this.name
}

output "S3_ECR_REPOSITORY" {
  value = aws_ecr_repository.s3_app.name
}

output "S3_ECS_SERVICE" {
  value = aws_ecs_service.s3_app.name
}

output "SQS_ECR_REPOSITORY" {
  value = aws_ecr_repository.sqs_app.name
}

output "SQS_ECS_SERVICE" {
  value = aws_ecs_service.sqs_app.name
}

# Handy for testing later
output "uploads_bucket" {
  value = aws_s3_bucket.uploads.bucket
}

output "queue_url" {
  value = aws_sqs_queue.messages.url
}