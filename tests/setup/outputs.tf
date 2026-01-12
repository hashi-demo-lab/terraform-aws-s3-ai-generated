# tests/setup/outputs.tf - Outputs from Test Fixtures

output "logging_target_bucket_id" {
  description = "ID of the logging target bucket for tests"
  value       = aws_s3_bucket.logging_target.id
}

output "logging_target_bucket_arn" {
  description = "ARN of the logging target bucket for tests"
  value       = aws_s3_bucket.logging_target.arn
}

output "test_suffix" {
  description = "Random suffix used for test resources"
  value       = random_id.test_suffix.hex
}

output "aws_account_id" {
  description = "AWS account ID for tests"
  value       = data.aws_caller_identity.current.account_id
}
