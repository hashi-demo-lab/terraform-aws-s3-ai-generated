# data.tf - Data Sources for AWS S3 Module
# This file defines data sources for account information and policy documents

#------------------------------------------------------------------------------
# AWS Account Information
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#------------------------------------------------------------------------------
# Logging Target Bucket Validation (P2-002)
#------------------------------------------------------------------------------

data "aws_s3_bucket" "logging_target" {
  count  = var.enable_logging && var.logging_target_bucket != null ? 1 : 0
  bucket = var.logging_target_bucket
}

#------------------------------------------------------------------------------
# KMS Key Policy Document (P1-002: Service-Specific Constraint)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "kms_key_policy" {
  count = local.create_kms_key ? 1 : 0

  # Allow AWS account root full access for key administration
  statement {
    sid    = "AllowRootAccountFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow S3 service to use the key (P1-002 fix: service-specific constraint)
  statement {
    sid    = "AllowS3ToUseKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow IAM principals to read key metadata
  statement {
    sid    = "AllowIAMReadOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow IAM principals to use the key via IAM policies
  statement {
    sid    = "AllowKeyUsageViaIAM"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Optional: Allow admin role to manage the key
  dynamic "statement" {
    for_each = var.kms_admin_role_arn != null ? [1] : []

    content {
      sid    = "AllowKeyAdministration"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [var.kms_admin_role_arn]
      }

      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource"
      ]

      resources = ["*"]
    }
  }
}

#------------------------------------------------------------------------------
# Bucket Policy: HTTPS Enforcement (Always Applied)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "require_https" {
  statement {
    sid    = "DenyNonHTTPS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

#------------------------------------------------------------------------------
# Bucket Policy: Server-Side Encryption Enforcement (P1-001)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "require_encryption" {
  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = local.allowed_encryption_headers
    }
  }
}

#------------------------------------------------------------------------------
# Bucket Policy: Website Public Read (Conditional)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "website_public" {
  count = var.enable_website ? 1 : 0

  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

#------------------------------------------------------------------------------
# Combined Bucket Policy Document
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact([
    data.aws_iam_policy_document.require_https.json,
    data.aws_iam_policy_document.require_encryption.json,
    var.enable_website ? data.aws_iam_policy_document.website_public[0].json : null,
    var.bucket_policy
  ])
}