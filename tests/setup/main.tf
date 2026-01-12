# tests/setup/main.tf - Test Fixtures for Integration Tests
# This creates supporting resources needed for integration tests

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Generate a unique suffix for test resources
resource "random_id" "test_suffix" {
  byte_length = 4
}

# Logging target bucket for testing logging configuration
resource "aws_s3_bucket" "logging_target" {
  bucket        = "tftest-logs-${random_id.test_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "tftest-logging-target"
    ManagedBy   = "TerraformTest"
    Purpose     = "IntegrationTestFixture"
    Application = "terraform-aws-s3-module-test"
    Environment = "test"
  }
}

# Enable versioning on logging bucket
resource "aws_s3_bucket_versioning" "logging_target" {
  bucket = aws_s3_bucket.logging_target.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block for logging bucket
resource "aws_s3_bucket_public_access_block" "logging_target" {
  bucket = aws_s3_bucket.logging_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for test logging bucket encryption
resource "aws_kms_key" "logging_target" {
  description             = "KMS key for test logging bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "tftest-logging-kms"
    Application = "terraform-aws-s3-module-test"
    Environment = "test"
    ManagedBy   = "TerraformTest"
  }
}

# Server-side encryption for logging bucket with CMK
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_target" {
  bucket = aws_s3_bucket.logging_target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logging_target.arn
    }
    bucket_key_enabled = true
  }
}

# Bucket policy for logging bucket to allow log delivery
resource "aws_s3_bucket_policy" "logging_target" {
  bucket = aws_s3_bucket.logging_target.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logging_target.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.logging_target]
}

data "aws_caller_identity" "current" {}
