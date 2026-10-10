variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Unique prefix for all resource names"
  type        = string
}

variable "github_app_repo" {
  description = "The app repository allowed to deploy, in the form owner/repo"
  type        = string
}

variable "vpc_name" {
  description = "Name tag of the class VPC to deploy into"
  type        = string
  default     = "sctp-vpc-ce13"
}