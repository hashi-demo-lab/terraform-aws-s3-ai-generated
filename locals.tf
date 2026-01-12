# locals.tf - Local Values and Computations for AWS S3 Module
# This file defines computed values used throughout the module

locals {
  #------------------------------------------------------------------------------
  # Bucket Name Resolution
  #------------------------------------------------------------------------------

  # Determine the final bucket name
  # If bucket_name is provided, use it directly
  # If bucket_prefix is provided, the actual name will be set by the bucket resource
  use_bucket_prefix = var.bucket_prefix != null
  bucket_name       = var.bucket_name != null ? var.bucket_name : null

  #------------------------------------------------------------------------------
  # KMS Key Configuration
  #------------------------------------------------------------------------------

  # Determine if a new KMS key should be created
  create_kms_key = var.encryption_type == "KMS" && var.kms_key_arn == null

  # Resolve the KMS key ARN to use (created or provided)
  kms_key_arn = local.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_arn

  # SSE algorithm based on encryption type
  sse_algorithm = var.encryption_type == "KMS" ? "aws:kms" : "AES256"

  # Allowed encryption headers for bucket policy (P1-001)
  allowed_encryption_headers = var.encryption_type == "KMS" ? ["aws:kms", "AES256"] : ["AES256"]

  #------------------------------------------------------------------------------
  # Website and Public Access Settings (P2-003)
  #------------------------------------------------------------------------------

  # When website hosting is enabled, automatically adjust public access blocks
  # to allow policy-based public access while still blocking ACL-based access
  website_block_public_policy     = var.enable_website ? false : var.block_public_policy
  website_restrict_public_buckets = var.enable_website ? false : var.restrict_public_buckets

  #------------------------------------------------------------------------------
  # Mandatory Tags (AWS-TAG-001 Compliance)
  #------------------------------------------------------------------------------

  # These tags are always applied to all resources
  mandatory_tags = {
    Application = var.application_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  #------------------------------------------------------------------------------
  # Common Tags (Merged)
  #------------------------------------------------------------------------------

  # Merge mandatory tags with user-provided tags
  # User tags take precedence for non-mandatory fields
  common_tags = merge(
    local.mandatory_tags,
    var.tags,
    {
      Name = local.use_bucket_prefix ? null : var.bucket_name
    }
  )

  # Filter out null values from tags
  final_tags = { for k, v in local.common_tags : k => v if v != null }

  #------------------------------------------------------------------------------
  # Versioning Status
  #------------------------------------------------------------------------------

  versioning_status = var.enable_versioning ? "Enabled" : "Suspended"

  #------------------------------------------------------------------------------
  # MFA Delete Status
  #------------------------------------------------------------------------------

  mfa_delete_status = var.enable_mfa_delete ? "Enabled" : "Disabled"
}
