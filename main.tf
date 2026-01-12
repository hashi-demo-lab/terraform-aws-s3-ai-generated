# main.tf - Primary Module Resources for AWS S3 Module
# This file defines all S3 bucket resources and configurations

#------------------------------------------------------------------------------
# Random ID for Bucket Prefix (T039)
#------------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  count = local.use_bucket_prefix ? 1 : 0

  byte_length = 8
  prefix      = var.bucket_prefix
}

#------------------------------------------------------------------------------
# KMS Key for SSE-KMS Encryption (T040, T041)
#------------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for S3 bucket ${local.use_bucket_prefix ? random_id.bucket_suffix[0].hex : var.bucket_name} encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation
  policy                  = data.aws_iam_policy_document.kms_key_policy[0].json

  tags = merge(local.final_tags, {
    Name = "${local.use_bucket_prefix ? random_id.bucket_suffix[0].hex : var.bucket_name}-kms-key"
  })
}

resource "aws_kms_alias" "this" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/s3-${local.use_bucket_prefix ? random_id.bucket_suffix[0].hex : var.bucket_name}"
  target_key_id = aws_kms_key.this[0].key_id
}

#------------------------------------------------------------------------------
# S3 Bucket Core Resource (T042)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = local.use_bucket_prefix ? random_id.bucket_suffix[0].hex : var.bucket_name
  force_destroy = var.force_destroy

  tags = local.final_tags

  # Cross-variable validations (P1 Finding)
  lifecycle {
    precondition {
      condition     = !(var.bucket_name != null && var.bucket_prefix != null)
      error_message = "Cannot specify both bucket_name and bucket_prefix. Please provide only one."
    }
    precondition {
      condition     = var.bucket_name != null || var.bucket_prefix != null
      error_message = "Either bucket_name or bucket_prefix must be provided."
    }
  }
}

#------------------------------------------------------------------------------
# Bucket Ownership Controls (T043)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

#------------------------------------------------------------------------------
# Bucket Versioning (T044)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = local.versioning_status
    mfa_delete = local.mfa_delete_status
  }

  # MFA delete validation (P2-001)
  lifecycle {
    precondition {
      condition     = !(var.enable_mfa_delete && !var.enable_versioning)
      error_message = "MFA delete requires versioning to be enabled. Set enable_versioning = true when using enable_mfa_delete = true."
    }
  }
}

#------------------------------------------------------------------------------
# Server-Side Encryption Configuration (T045)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = var.encryption_type == "KMS" ? local.kms_key_arn : null
    }
    bucket_key_enabled = var.encryption_type == "KMS" ? true : null
  }
}

#------------------------------------------------------------------------------
# Public Access Block (T046)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = local.website_block_public_policy
  restrict_public_buckets = local.website_restrict_public_buckets
}

#------------------------------------------------------------------------------
# Bucket Policy (T047)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined.json

  # Ensure public access block is set before applying policy
  depends_on = [aws_s3_bucket_public_access_block.this]
}

#------------------------------------------------------------------------------
# Server Access Logging (Conditional)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix

  # Precondition validation (P2-002)
  lifecycle {
    precondition {
      condition     = var.logging_target_bucket != null
      error_message = "logging_target_bucket must be specified when enable_logging is true."
    }
  }
}

#------------------------------------------------------------------------------
# Static Website Configuration (Conditional)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.website_index_document
  }

  error_document {
    key = var.website_error_document
  }
}

#------------------------------------------------------------------------------
# CORS Configuration (Conditional)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      id              = cors_rule.value.id
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

#------------------------------------------------------------------------------
# Lifecycle Configuration (Conditional)
#------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # Lifecycle depends on versioning for noncurrent version rules
  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filter block
      filter {
        and {
          prefix = rule.value.prefix
          tags   = rule.value.tags
        }
      }

      # Transitions
      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions

        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
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

      # Abort incomplete multipart uploads
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}
