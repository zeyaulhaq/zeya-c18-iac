# ---------- S3 bucket for Service 1 uploads ----------
resource "aws_s3_bucket" "uploads" {
  # bucket names are global, so add the account id to keep it unique
  bucket        = "${var.name_prefix}-c18-uploads-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # allow destroy even when files are inside
}

# Make sure the bucket can never be made public
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- SQS queue for Service 2 messages ----------
resource "aws_sqs_queue" "messages" {
  name                    = "${var.name_prefix}-c18-messages"
  sqs_managed_sse_enabled = true # encrypt messages at rest
}