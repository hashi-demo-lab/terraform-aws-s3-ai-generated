# tests/integration-tests.tftest.hcl - Integration Tests for AWS S3 Module
# These tests create real AWS resources and verify behavior
# Execution: terraform test -filter=tests/integration-tests.tftest.hcl

#------------------------------------------------------------------------------
# Test Provider Configuration
#------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      TestSuite = "terraform-aws-s3-module-integration"
      ManagedBy = "TerraformTest"
    }
  }
}

#------------------------------------------------------------------------------
# Test: Basic Bucket Creation (T048)
#------------------------------------------------------------------------------

run "basic_bucket_creation" {
  command = apply

  variables {
    bucket_prefix    = "tftest-basic"
    application_name = "integration-test"
    environment      = "dev"
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null && output.bucket_id != ""
    error_message = "Bucket ID should be set"
  }

  # Verify bucket ARN format
  assert {
    condition     = can(regex("^arn:aws:s3:::", output.bucket_arn))
    error_message = "Bucket ARN should be valid S3 ARN format"
  }

  # Verify versioning is enabled
  assert {
    condition     = output.versioning_status == "Enabled"
    error_message = "Versioning should be Enabled by default"
  }

  # Verify encryption type
  assert {
    condition     = output.encryption_type == "AES256"
    error_message = "Encryption type should be AES256 by default"
  }

  # Verify public access blocks
  assert {
    condition     = output.effective_public_access_block.block_public_acls == true
    error_message = "block_public_acls should be true"
  }

  assert {
    condition     = output.effective_public_access_block.block_public_policy == true
    error_message = "block_public_policy should be true"
  }

  assert {
    condition     = output.effective_public_access_block.ignore_public_acls == true
    error_message = "ignore_public_acls should be true"
  }

  assert {
    condition     = output.effective_public_access_block.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true"
  }
}

#------------------------------------------------------------------------------
# Test: KMS Encryption Bucket
#------------------------------------------------------------------------------

run "kms_encryption_bucket" {
  command = apply

  variables {
    bucket_prefix    = "tftest-kms"
    application_name = "integration-test"
    environment      = "dev"
    encryption_type  = "KMS"
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket should be created"
  }

  # Verify KMS key is created
  assert {
    condition     = output.kms_key_arn != null
    error_message = "KMS key ARN should be set"
  }

  assert {
    condition     = output.kms_key_id != null
    error_message = "KMS key ID should be set"
  }

  # Verify encryption type
  assert {
    condition     = output.encryption_type == "KMS"
    error_message = "Encryption type should be KMS"
  }
}

#------------------------------------------------------------------------------
# Test: Website Bucket Creation (T067)
#------------------------------------------------------------------------------

run "website_bucket_creation" {
  command = apply

  variables {
    bucket_prefix    = "tftest-website"
    application_name = "integration-test"
    environment      = "dev"
    enable_website   = true
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket should be created"
  }

  # Verify website endpoint is set
  assert {
    condition     = output.website_endpoint != null
    error_message = "Website endpoint should be set when website is enabled"
  }

  # Verify website domain is set
  assert {
    condition     = output.website_domain != null
    error_message = "Website domain should be set when website is enabled"
  }

  # Verify public access blocks are adjusted for website
  assert {
    condition     = output.effective_public_access_block.block_public_policy == false
    error_message = "block_public_policy should be false for website"
  }

  assert {
    condition     = output.effective_public_access_block.restrict_public_buckets == false
    error_message = "restrict_public_buckets should be false for website"
  }
}

#------------------------------------------------------------------------------
# Test: Lifecycle Rules Applied (T079)
#------------------------------------------------------------------------------

run "lifecycle_rules_applied" {
  command = apply

  variables {
    bucket_prefix    = "tftest-lifecycle"
    application_name = "integration-test"
    environment      = "dev"
    lifecycle_rules = [
      {
        id      = "archive-rule"
        enabled = true
        prefix  = "logs/"
        transitions = [
          { days = 30, storage_class = "STANDARD_IA" },
          { days = 90, storage_class = "GLACIER" }
        ]
        expiration = {
          days = 365
        }
      }
    ]
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket should be created"
  }
}

#------------------------------------------------------------------------------
# Test: CORS Configuration
#------------------------------------------------------------------------------

run "cors_configuration" {
  command = apply

  variables {
    bucket_prefix    = "tftest-cors"
    application_name = "integration-test"
    environment      = "dev"
    cors_rules = [
      {
        id              = "allow-all-get"
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["*"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3000
      }
    ]
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket should be created"
  }
}

#------------------------------------------------------------------------------
# Test: Custom Tags Applied
#------------------------------------------------------------------------------

run "custom_tags_applied" {
  command = apply

  variables {
    bucket_prefix    = "tftest-tags"
    application_name = "integration-test"
    environment      = "prod"
    tags = {
      Project    = "TestProject"
      CostCenter = "Engineering"
    }
  }

  # Verify bucket is created
  assert {
    condition     = output.bucket_id != null
    error_message = "Bucket should be created"
  }
}

#------------------------------------------------------------------------------
# Test: Versioning Disabled
#------------------------------------------------------------------------------

run "versioning_disabled" {
  command = apply

  variables {
    bucket_prefix     = "tftest-noversion"
    application_name  = "integration-test"
    environment       = "dev"
    enable_versioning = false
  }

  # Verify versioning status
  assert {
    condition     = output.versioning_status == "Suspended"
    error_message = "Versioning should be Suspended when disabled"
  }
}
