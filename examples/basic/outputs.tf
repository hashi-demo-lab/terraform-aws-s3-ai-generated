# examples/basic/outputs.tf - Outputs for Basic Example

output "bucket_id" {
  description = "The name of the bucket"
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.s3_bucket.bucket_arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = module.s3_bucket.bucket_domain_name
}

output "versioning_status" {
  description = "The versioning status"
  value       = module.s3_bucket.versioning_status
}

output "encryption_type" {
  description = "The encryption type"
  value       = module.s3_bucket.encryption_type
}
