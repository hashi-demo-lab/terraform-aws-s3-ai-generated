# examples/website/outputs.tf - Outputs for Website Example

output "bucket_id" {
  description = "The name of the bucket"
  value       = module.website_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.website_bucket.bucket_arn
}

output "website_endpoint" {
  description = "The website endpoint URL"
  value       = module.website_bucket.website_endpoint
}

output "website_domain" {
  description = "The website domain"
  value       = module.website_bucket.website_domain
}

output "website_url" {
  description = "The full website URL"
  value       = "http://${module.website_bucket.website_endpoint}"
}

output "effective_public_access_block" {
  description = "The effective public access block settings"
  value       = module.website_bucket.effective_public_access_block
}
