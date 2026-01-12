# tests/unit-tests.tftest.hcl - Unit Tests for AWS S3 Module
# These tests validate variable validation, defaults, and conditional logic
# Execution: terraform test -filter=tests/unit-tests.tftest.hcl

#------------------------------------------------------------------------------
# Mock Providers
#------------------------------------------------------------------------------

mock_provider "aws" {}
mock_provider "random" {}

#------------------------------------------------------------------------------
# Test: Invalid Bucket Name Rejected (T030)
#------------------------------------------------------------------------------

run "invalid_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name      = "INVALID_UPPERCASE"
    application_name = "test-app"
    environment      = "dev"
  }

  expect_failures = [var.bucket_name]
}

run "invalid_bucket_name_too_short" {
  command = plan

  variables {
    bucket_name      = "ab"
    application_name = "test-app"
    environment      = "dev"
  }

  expect_failures = [var.bucket_name]
}

#------------------------------------------------------------------------------
# Test: Valid Bucket Name Accepted (T031)
#------------------------------------------------------------------------------

run "valid_bucket_name_accepted" {
  command = plan

  variables {
    bucket_name      = "my-valid-bucket-name-12345"
    application_name = "test-app"
    environment      = "dev"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "my-valid-bucket-name-12345"
    error_message = "Bucket should be created with the valid name"
  }
}

#------------------------------------------------------------------------------
# Test: Invalid Encryption Type Rejected (T032)
#------------------------------------------------------------------------------

run "invalid_encryption_type_rejected" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    environment      = "dev"
    encryption_type  = "INVALID"
  }

  expect_failures = [var.encryption_type]
}

#------------------------------------------------------------------------------
# Test: Invalid KMS Deletion Window Rejected (T033)
#------------------------------------------------------------------------------

run "invalid_kms_deletion_window_too_low" {
  command = plan

  variables {
    bucket_name             = "test-bucket-12345"
    application_name        = "test-app"
    environment             = "dev"
    encryption_type         = "KMS"
    kms_key_deletion_window = 5
  }

  expect_failures = [var.kms_key_deletion_window]
}

run "invalid_kms_deletion_window_too_high" {
  command = plan

  variables {
    bucket_name             = "test-bucket-12345"
    application_name        = "test-app"
    environment             = "dev"
    encryption_type         = "KMS"
    kms_key_deletion_window = 31
  }

  expect_failures = [var.kms_key_deletion_window]
}

#------------------------------------------------------------------------------
# Test: Invalid Environment Rejected (T034)
#------------------------------------------------------------------------------

run "invalid_environment_rejected" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    environment      = "production"
  }

  expect_failures = [var.environment]
}

#------------------------------------------------------------------------------
# Test: Default Values Applied (T035)
#------------------------------------------------------------------------------

run "default_values_applied" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
  }

  # Verify versioning is enabled by default
  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled by default"
  }

  # Verify AES256 encryption by default
  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "AES256 encryption should be enabled by default"
  }

  # Verify all public access blocks enabled by default
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy should be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls should be true by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true by default"
  }
}

#------------------------------------------------------------------------------
# Test: Bucket Policy Includes HTTPS Enforcement (T036)
#------------------------------------------------------------------------------

run "bucket_policy_includes_https_enforcement" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    environment      = "dev"
  }

  assert {
    condition     = can(regex("DenyNonHTTPS", data.aws_iam_policy_document.require_https.json))
    error_message = "Bucket policy should include HTTPS enforcement statement"
  }

  assert {
    condition     = can(regex("aws:SecureTransport", data.aws_iam_policy_document.require_https.json))
    error_message = "Bucket policy should use aws:SecureTransport condition"
  }
}

#------------------------------------------------------------------------------
# Test: Bucket Policy Includes Encryption Enforcement (T037 - P1-001)
#------------------------------------------------------------------------------

run "bucket_policy_includes_encryption_enforcement" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    environment      = "dev"
  }

  assert {
    condition     = can(regex("DenyUnencryptedUploads", data.aws_iam_policy_document.require_encryption.json))
    error_message = "Bucket policy should include encryption enforcement statement"
  }

  assert {
    condition     = can(regex("s3:x-amz-server-side-encryption", data.aws_iam_policy_document.require_encryption.json))
    error_message = "Bucket policy should check for server-side encryption header"
  }
}

#------------------------------------------------------------------------------
# Test: KMS Key Policy Uses Least Privilege (T038 - P1-002)
#------------------------------------------------------------------------------

run "kms_key_policy_uses_least_privilege" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    environment      = "dev"
    encryption_type  = "KMS"
  }

  # Verify KMS key is created
  assert {
    condition     = length(aws_kms_key.this) == 1
    error_message = "KMS key should be created when encryption_type is KMS"
  }

  # Verify S3 service principal in key policy
  assert {
    condition     = can(regex("s3.amazonaws.com", data.aws_iam_policy_document.kms_key_policy[0].json))
    error_message = "KMS key policy should include S3 service principal"
  }

  # Verify CallerAccount condition
  assert {
    condition     = can(regex("kms:CallerAccount", data.aws_iam_policy_document.kms_key_policy[0].json))
    error_message = "KMS key policy should restrict access to caller account"
  }
}

#------------------------------------------------------------------------------
# Test: Bucket Name/Prefix Mutual Exclusivity (P1 Finding)
#------------------------------------------------------------------------------

run "bucket_name_and_prefix_mutually_exclusive" {
  command = plan

  variables {
    bucket_name      = "test-bucket"
    bucket_prefix    = "test-prefix"
    application_name = "test-app"
  }

  expect_failures = [aws_s3_bucket.this]
}

run "bucket_name_or_prefix_required" {
  command = plan

  variables {
    application_name = "test-app"
  }

  expect_failures = [aws_s3_bucket.this]
}

#------------------------------------------------------------------------------
# Test: MFA Delete Requires Versioning (P2-001)
#------------------------------------------------------------------------------

run "mfa_delete_requires_versioning" {
  command = plan

  variables {
    bucket_name       = "test-bucket-12345"
    application_name  = "test-app"
    enable_versioning = false
    enable_mfa_delete = true
  }

  expect_failures = [aws_s3_bucket_versioning.this]
}

#------------------------------------------------------------------------------
# Test: Website Public Access Adjusted (T054)
#------------------------------------------------------------------------------

run "website_public_access_adjusted" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    enable_website   = true
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == false
    error_message = "block_public_policy should be false when website is enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == false
    error_message = "restrict_public_buckets should be false when website is enabled"
  }

  # ACL blocks should remain true
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should still be true when website is enabled"
  }
}

#------------------------------------------------------------------------------
# Test: CORS Rules Max Exceeded (T055)
#------------------------------------------------------------------------------

run "cors_rules_max_exceeded" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    cors_rules = [
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] },
      { allowed_methods = ["GET"], allowed_origins = ["*"] }
    ]
  }

  expect_failures = [var.cors_rules]
}

#------------------------------------------------------------------------------
# Test: Lifecycle Rules Max Exceeded (T072)
#------------------------------------------------------------------------------

run "lifecycle_rules_max_exceeded" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    lifecycle_rules = [
      for i in range(51) : {
        id      = "rule-${i}"
        enabled = true
      }
    ]
  }

  expect_failures = [var.lifecycle_rules]
}

#------------------------------------------------------------------------------
# Test: Lifecycle Storage Class Validation (T073)
#------------------------------------------------------------------------------

run "lifecycle_storage_class_invalid" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    lifecycle_rules = [
      {
        id      = "test-rule"
        enabled = true
        transitions = [
          { days = 30, storage_class = "INVALID_CLASS" }
        ]
      }
    ]
  }

  expect_failures = [var.lifecycle_rules]
}

#------------------------------------------------------------------------------
# Test: Lifecycle Transition Days Validation (T028)
#------------------------------------------------------------------------------

run "lifecycle_transition_days_negative" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    lifecycle_rules = [
      {
        id      = "test-rule"
        enabled = true
        transitions = [
          { days = -1, storage_class = "GLACIER" }
        ]
      }
    ]
  }

  expect_failures = [var.lifecycle_rules]
}

#------------------------------------------------------------------------------
# Test: Bucket Prefix Creates Random Suffix
#------------------------------------------------------------------------------

run "bucket_prefix_creates_random_suffix" {
  command = plan

  variables {
    bucket_prefix    = "my-prefix"
    application_name = "test-app"
  }

  assert {
    condition     = length(random_id.bucket_suffix) == 1
    error_message = "Random suffix should be created when using bucket_prefix"
  }
}

#------------------------------------------------------------------------------
# Test: Application Name Validation
#------------------------------------------------------------------------------

run "application_name_required" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = ""
  }

  expect_failures = [var.application_name]
}

#------------------------------------------------------------------------------
# Test: KMS Key Not Created for AES256
#------------------------------------------------------------------------------

run "no_kms_key_for_aes256" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    encryption_type  = "AES256"
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "KMS key should not be created when encryption_type is AES256"
  }
}

#------------------------------------------------------------------------------
# Test: Existing KMS Key Used
#------------------------------------------------------------------------------

run "existing_kms_key_used" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    encryption_type  = "KMS"
    kms_key_arn      = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "KMS key should not be created when kms_key_arn is provided"
  }
}

#------------------------------------------------------------------------------
# Test: Website Configuration Created
#------------------------------------------------------------------------------

run "website_configuration_created" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    enable_website   = true
  }

  assert {
    condition     = length(aws_s3_bucket_website_configuration.this) == 1
    error_message = "Website configuration should be created when enable_website is true"
  }
}

#------------------------------------------------------------------------------
# Test: CORS Configuration Created
#------------------------------------------------------------------------------

run "cors_configuration_created" {
  command = plan

  variables {
    bucket_name      = "test-bucket-12345"
    application_name = "test-app"
    cors_rules = [
      {
        allowed_methods = ["GET"]
        allowed_origins = ["https://example.com"]
      }
    ]
  }

  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 1
    error_message = "CORS configuration should be created when cors_rules is not empty"
  }
}
