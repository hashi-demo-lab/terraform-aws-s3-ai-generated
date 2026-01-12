# examples/complete/outputs.tf - Outputs for Complete Example

#------------------------------------------------------------------------------
# Logging Bucket Outputs
#------------------------------------------------------------------------------

output "logging_bucket_id" {
  description = "The name of the logging bucket"
  value       = module.logging_bucket.bucket_id
}

output "logging_bucket_arn" {
  description = "The ARN of the logging bucket"
  value       = module.logging_bucket.bucket_arn
}

#------------------------------------------------------------------------------
# Data Lake Bucket Outputs
#------------------------------------------------------------------------------

output "datalake_bucket_id" {
  description = "The name of the data lake bucket"
  value       = module.datalake_bucket.bucket_id
}

output "datalake_bucket_arn" {
  description = "The ARN of the data lake bucket"
  value       = module.datalake_bucket.bucket_arn
}

output "datalake_bucket_domain_name" {
  description = "The domain name of the data lake bucket"
  value       = module.datalake_bucket.bucket_domain_name
}

output "datalake_bucket_regional_domain_name" {
  description = "The regional domain name of the data lake bucket"
  value       = module.datalake_bucket.bucket_regional_domain_name
}

#------------------------------------------------------------------------------
# KMS Key Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = module.datalake_bucket.kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = module.datalake_bucket.kms_key_id
}

#------------------------------------------------------------------------------
# Configuration Status Outputs
#------------------------------------------------------------------------------

output "versioning_status" {
  description = "The versioning status of the data lake bucket"
  value       = module.datalake_bucket.versioning_status
}

output "encryption_type" {
  description = "The encryption type of the data lake bucket"
  value       = module.datalake_bucket.encryption_type
}

output "logging_target_bucket" {
  description = "The logging target bucket"
  value       = module.datalake_bucket.logging_target_bucket
}
