# examples/basic/main.tf - Basic Secure Bucket Example
# This example demonstrates the minimal configuration for a secure S3 bucket

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_bucket" {
  source = "../../"

  # Required variables
  bucket_name      = var.bucket_name
  application_name = var.application_name
  environment      = var.environment

  # Optional: Additional tags
  tags = var.tags
}
