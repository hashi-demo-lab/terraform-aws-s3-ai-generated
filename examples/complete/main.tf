# examples/complete/main.tf - Complete Full-Featured Example
# This example demonstrates all features of the S3 module

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

# Create a logging bucket first
module "logging_bucket" {
  source = "../../"

  bucket_prefix    = "logs-${var.application_name}"
  application_name = var.application_name
  environment      = var.environment

  # Logging bucket doesn't need versioning for logs
  enable_versioning = false

  # Lifecycle rules for log retention
  lifecycle_rules = [
    {
      id      = "log-expiration"
      enabled = true
      expiration = {
        days = 90
      }
    }
  ]

  tags = merge(var.tags, {
    Purpose = "S3AccessLogs"
  })
}

# Create the main data lake bucket with all features
module "datalake_bucket" {
  source = "../../"

  bucket_prefix    = "datalake-${var.application_name}"
  application_name = var.application_name
  environment      = var.environment

  # KMS encryption for sensitive data
  encryption_type         = "KMS"
  enable_kms_key_rotation = true
  kms_key_deletion_window = 30

  # Enable versioning for data protection
  enable_versioning = true

  # Enable access logging
  enable_logging        = true
  logging_target_bucket = module.logging_bucket.bucket_id
  logging_target_prefix = "datalake-access-logs/"

  # Lifecycle rules for cost optimization
  lifecycle_rules = var.lifecycle_rules

  # CORS rules if needed for web access
  cors_rules = var.cors_rules

  tags = merge(var.tags, {
    Purpose  = "DataLake"
    DataTier = "Gold"
  })

  depends_on = [module.logging_bucket]
}
