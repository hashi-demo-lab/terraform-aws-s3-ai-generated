# outputs.tf - Output Value Definitions for AWS S3 Module
# This file exports key values for use by other modules and configurations

#------------------------------------------------------------------------------
# Bucket Identifiers
#------------------------------------------------------------------------------

output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

#------------------------------------------------------------------------------
# Bucket Endpoints
#------------------------------------------------------------------------------

output "bucket_domain_name" {
  description = "The bucket domain name (format: bucketname.s3.amazonaws.com)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for the bucket region."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "bucket_region" {
  description = "The AWS region the bucket resides in."
  value       = aws_s3_bucket.this.region
}

#------------------------------------------------------------------------------
# KMS Key Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "The ARN of the KMS key (if created by this module)."
  value       = local.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the KMS key (if created by this module)."
  value       = local.create_kms_key ? aws_kms_key.this[0].key_id : null
}

#------------------------------------------------------------------------------
# Configuration Status Outputs
#------------------------------------------------------------------------------

output "logging_target_bucket" {
  description = "The logging target bucket name (if logging is enabled)."
  value       = var.enable_logging ? var.logging_target_bucket : null
}

output "versioning_status" {
  description = "The versioning state of the bucket (Enabled or Suspended)."
  value       = local.versioning_status
}

output "encryption_type" {
  description = "The encryption type configured for the bucket (AES256 or KMS)."
  value       = var.encryption_type
}

#------------------------------------------------------------------------------
# Website Outputs
#------------------------------------------------------------------------------

output "website_endpoint" {
  description = "The website endpoint (if static website hosting is enabled)."
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_domain" {
  description = "The domain of the website endpoint (if static website hosting is enabled)."
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_domain : null
}

#------------------------------------------------------------------------------
# Public Access Block Status (P2-003)
#------------------------------------------------------------------------------

output "effective_public_access_block" {
  description = "The effective public access block settings applied to the bucket."
  value = {
    block_public_acls       = var.block_public_acls
    ignore_public_acls      = var.ignore_public_acls
    block_public_policy     = local.website_block_public_policy
    restrict_public_buckets = local.website_restrict_public_buckets
  }
}
