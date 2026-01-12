# examples/website/main.tf - Static Website Hosting Example
# This example demonstrates S3 bucket configuration for static website hosting

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

module "website_bucket" {
  source = "../../"

  # Required variables
  bucket_name      = var.bucket_name
  application_name = var.application_name
  environment      = var.environment

  # Website configuration
  enable_website         = true
  website_index_document = var.website_index_document
  website_error_document = var.website_error_document

  # CORS configuration for web access
  cors_rules = var.cors_rules

  # Optional: Additional tags
  tags = var.tags
}
