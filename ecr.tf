# Image repository for Service 1 (S3 app)
resource "aws_ecr_repository" "s3_app" {
  name                 = "${var.name_prefix}-flask-s3-service"
  image_tag_mutability = "MUTABLE" # we re-push the "latest" tag on every deploy
  force_delete         = true      # lets terraform destroy work even if images exist

  image_scanning_configuration {
    scan_on_push = true # AWS scans each image for known vulnerabilities
  }
}

# Image repository for Service 2 (SQS app)
resource "aws_ecr_repository" "sqs_app" {
  name                 = "${var.name_prefix}-flask-sqs-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}