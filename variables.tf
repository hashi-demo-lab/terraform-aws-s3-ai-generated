# variables.tf - Input Variable Definitions for AWS S3 Module
# This file defines all configurable inputs for the module

#------------------------------------------------------------------------------
# Core Bucket Configuration
#------------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique). Either bucket_name or bucket_prefix must be provided."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, and periods only. Must start and end with a letter or number."
  }
}

variable "bucket_prefix" {
  description = "Prefix for bucket name with random suffix for uniqueness. Max 37 characters. Conflicts with bucket_name."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_prefix == null || (length(var.bucket_prefix) <= 37 && can(regex("^[a-z0-9][a-z0-9.-]*$", var.bucket_prefix)))
    error_message = "Bucket prefix must be max 37 characters, lowercase letters, numbers, hyphens, and periods only. Must start with a letter or number."
  }
}

variable "application_name" {
  description = "Name of the application using this bucket. Required for AWS-TAG-001 compliance."
  type        = string

  validation {
    condition     = length(var.application_name) >= 1 && length(var.application_name) <= 128
    error_message = "Application name must be between 1 and 128 characters."
  }
}

variable "environment" {
  description = "Environment tag value (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects inside. Use with caution in production."
  type        = bool
  default     = false
}


#------------------------------------------------------------------------------
# Versioning Configuration
#------------------------------------------------------------------------------

variable "enable_versioning" {
  description = "Enable versioning on the bucket. Recommended for data protection."
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete for versioned objects. Requires versioning to be enabled."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Encryption Configuration
#------------------------------------------------------------------------------

variable "encryption_type" {
  description = "Server-side encryption type: AES256 (SSE-S3) or KMS (SSE-KMS)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either 'AES256' or 'KMS'."
  }
}

variable "kms_key_arn" {
  description = "ARN of existing KMS key for SSE-KMS. If null and encryption_type is KMS, a new key is created."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-f0-9-]+$", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN format."
  }
}

variable "kms_key_deletion_window" {
  description = "Days before KMS key deletion (7-30 days)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic annual KMS key rotation."
  type        = bool
  default     = true
}

variable "kms_admin_role_arn" {
  description = "ARN of IAM role granted KMS key administration permissions."
  type        = string
  default     = null

  validation {
    condition     = var.kms_admin_role_arn == null || can(regex("^arn:aws:iam::[0-9]+:role/.+$", var.kms_admin_role_arn))
    error_message = "KMS admin role ARN must be a valid AWS IAM role ARN format."
  }
}

#------------------------------------------------------------------------------
# Public Access Configuration
#------------------------------------------------------------------------------

variable "block_public_acls" {
  description = "Block public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies for this bucket."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Logging Configuration
#------------------------------------------------------------------------------

variable "enable_logging" {
  description = "Enable server access logging for the bucket."
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs. Required when enable_logging is true."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for log objects in the target bucket."
  type        = string
  default     = "logs/"
}

#------------------------------------------------------------------------------
# Website Hosting Configuration
#------------------------------------------------------------------------------

variable "enable_website" {
  description = "Enable static website hosting for the bucket."
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "Index document for static website hosting."
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for static website hosting."
  type        = string
  default     = "error.html"
}

#------------------------------------------------------------------------------
# CORS Configuration
#------------------------------------------------------------------------------

variable "cors_rules" {
  description = <<-EOT
    List of CORS rule configurations (max 10 rules).
    Each rule specifies allowed origins, methods, headers, and caching behavior.

    Example:
    cors_rules = [
      {
        id              = "allow-website"
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["https://example.com"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3000
      }
    ]
  EOT

  type = list(object({
    id              = optional(string)
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))

  default = []

  validation {
    condition     = length(var.cors_rules) <= 10
    error_message = "Maximum 10 CORS rules allowed per bucket."
  }
}

#------------------------------------------------------------------------------
# Lifecycle Configuration
#------------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = <<-EOT
    List of lifecycle rule configurations (max 50 rules).
    Supports transitions to various storage classes and expiration.

    Valid storage classes: STANDARD_IA, INTELLIGENT_TIERING, GLACIER_IR, GLACIER, DEEP_ARCHIVE

    Example:
    lifecycle_rules = [
      {
        id      = "archive-old-data"
        enabled = true
        prefix  = "logs/"
        transitions = [
          { days = 30,  storage_class = "STANDARD_IA" },
          { days = 90,  storage_class = "GLACIER" }
        ]
        expiration = { days = 365 }
        noncurrent_version_expiration = { noncurrent_days = 30 }
      }
    ]
  EOT

  type = list(object({
    id      = string
    enabled = optional(bool, true)
    prefix  = optional(string)
    tags    = optional(map(string))

    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])

    expiration = optional(object({
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number)
    }))

    abort_incomplete_multipart_upload_days = optional(number)
  }))

  default = []

  validation {
    condition     = length(var.lifecycle_rules) <= 50
    error_message = "Maximum 50 lifecycle rules allowed per bucket."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : alltrue([
        for transition in rule.transitions :
        contains(["STANDARD_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "GLACIER", "DEEP_ARCHIVE", "ONEZONE_IA"], transition.storage_class)
      ])
    ])
    error_message = "Invalid storage class in lifecycle transitions. Valid values: STANDARD_IA, INTELLIGENT_TIERING, GLACIER_IR, GLACIER, DEEP_ARCHIVE, ONEZONE_IA."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : alltrue([
        for transition in rule.transitions :
        transition.days >= 0
      ])
    ])
    error_message = "Lifecycle transition days must be >= 0."
  }
}

#------------------------------------------------------------------------------
# Bucket Policy Configuration
#------------------------------------------------------------------------------

variable "bucket_policy" {
  description = "Custom bucket policy JSON. Will be merged with HTTPS enforcement policy."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_policy == null || can(jsondecode(var.bucket_policy))
    error_message = "Bucket policy must be valid JSON."
  }
}

#------------------------------------------------------------------------------
# Object Ownership Configuration
#------------------------------------------------------------------------------

variable "object_ownership" {
  description = "Object ownership setting. BucketOwnerEnforced disables ACLs."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "Object ownership must be one of: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}
