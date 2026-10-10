terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Where Terraform stores its state file (the bucket you created in Step 4)
  backend "s3" {
    bucket       = "zeyaulhaq-c18-tfstate-255945442255"
    key          = "coaching18/ecs-multi-service/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # stops two runs editing the state at the same time
  }
}

provider "aws" {
  region = var.aws_region

  # These tags are added to every resource automatically
  default_tags {
    tags = {
      Project   = "coaching18-ecs-multi-service"
      Owner     = var.name_prefix
      ManagedBy = "terraform"
    }
  }
}

# Looks up your AWS account number (used to make bucket names unique)
data "aws_caller_identity" "current" {}