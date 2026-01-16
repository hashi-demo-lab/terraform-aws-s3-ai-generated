# -----------------------------------------------------------------------------
# Core S3 Bucket Resource
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Bucket Ownership Controls (Security Review Finding #3)
# Enforces bucket owner ownership for all objects, preventing ACL-based access
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# -----------------------------------------------------------------------------
# Server-Side Encryption Configuration (SSE-KMS)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# -----------------------------------------------------------------------------
# Public Access Block Configuration
# All settings default to true for security; must be explicitly disabled for website hosting
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# -----------------------------------------------------------------------------
# Bucket Versioning Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# -----------------------------------------------------------------------------
# Server Access Logging Configuration (Conditional)
# Created when enable_logging is true and logging_bucket is provided
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "this" {
  count = local.create_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix
}

# -----------------------------------------------------------------------------
# Lifecycle Configuration (Conditional)
# Created when lifecycle_rules is not empty
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.create_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filter configuration - use 'and' block only when tags are present
      dynamic "filter" {
        for_each = length(rule.value.tags) > 0 ? [1] : []
        content {
          and {
            prefix = rule.value.prefix
            tags   = rule.value.tags
          }
        }
      }

      # Simple prefix filter when no tags
      dynamic "filter" {
        for_each = length(rule.value.tags) == 0 ? [1] : []
        content {
          prefix = rule.value.prefix
        }
      }

      # Storage class transitions
      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Object expiration
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions != null ? rule.value.noncurrent_version_transitions : []
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      # Abort incomplete multipart upload
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Website Configuration (Conditional)
# Created when website_configuration is provided
# Requires all public access blocks to be disabled
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_website_configuration" "this" {
  count = local.create_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.website_configuration.index_document
  }

  error_document {
    key = var.website_configuration.error_document
  }
}