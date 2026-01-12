# Data Model: Terraform AWS S3 Module

**Feature**: terraform-aws-s3-module
**Date**: 2026-01-11
**Version**: 1.0.0

---

## 1. Input Variables

### 1.1 Core Bucket Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `bucket_name` | `string` | Yes* | - | DNS-compliant, 3-63 chars, lowercase | Name of the S3 bucket (must be globally unique) |
| `bucket_prefix` | `string` | No | `null` | Max 37 chars, lowercase | Prefix for bucket name with random suffix (conflicts with bucket_name) |
| `environment` | `string` | No | `"dev"` | One of: dev, staging, prod | Environment tag value |
| `tags` | `map(string)` | No | `{}` | - | Additional tags to apply to all resources |
| `force_destroy` | `bool` | No | `false` | - | Allow bucket deletion with objects inside |

*Either `bucket_name` or `bucket_prefix` must be provided.

### 1.2 Versioning Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `enable_versioning` | `bool` | No | `true` | - | Enable versioning on the bucket |
| `enable_mfa_delete` | `bool` | No | `false` | - | Enable MFA delete for versioned objects |

### 1.3 Encryption Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `encryption_type` | `string` | No | `"AES256"` | One of: AES256, KMS | Server-side encryption type |
| `kms_key_arn` | `string` | No | `null` | Valid ARN format or null | ARN of existing KMS key (creates new if null and encryption_type is KMS) |
| `kms_key_deletion_window` | `number` | No | `30` | 7-30 inclusive | Days before KMS key deletion |
| `enable_kms_key_rotation` | `bool` | No | `true` | - | Enable automatic KMS key rotation |
| `kms_admin_role_arn` | `string` | No | `null` | Valid ARN format or null | ARN of IAM role for KMS key administration |

### 1.4 Public Access Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `block_public_acls` | `bool` | No | `true` | - | Block public ACLs |
| `block_public_policy` | `bool` | No | `true` | - | Block public bucket policies |
| `ignore_public_acls` | `bool` | No | `true` | - | Ignore public ACLs |
| `restrict_public_buckets` | `bool` | No | `true` | - | Restrict public bucket policies |

### 1.5 Logging Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `enable_logging` | `bool` | No | `false` | - | Enable server access logging |
| `logging_target_bucket` | `string` | No | `null` | Must exist if logging enabled | Target bucket for access logs |
| `logging_target_prefix` | `string` | No | `"logs/"` | - | Prefix for log objects |

### 1.6 Website Hosting Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `enable_website` | `bool` | No | `false` | - | Enable static website hosting |
| `website_index_document` | `string` | No | `"index.html"` | - | Index document for website |
| `website_error_document` | `string` | No | `"error.html"` | - | Error document for website |

### 1.7 CORS Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `cors_rules` | `list(object)` | No | `[]` | Max 10 rules | List of CORS rule configurations |

**CORS Rule Object Structure:**
```hcl
cors_rules = list(object({
  id              = optional(string)        # Unique identifier for the rule
  allowed_headers = optional(list(string))  # Headers allowed in preflight request
  allowed_methods = list(string)            # HTTP methods allowed (GET, PUT, POST, DELETE, HEAD)
  allowed_origins = list(string)            # Origins allowed to access the bucket
  expose_headers  = optional(list(string))  # Headers exposed to the client
  max_age_seconds = optional(number)        # Cache time for preflight response
}))
```

### 1.8 Lifecycle Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `lifecycle_rules` | `list(object)` | No | `[]` | Max 50 rules | List of lifecycle rule configurations |

**Lifecycle Rule Object Structure:**
```hcl
lifecycle_rules = list(object({
  id      = string                           # Unique rule identifier
  enabled = optional(bool, true)             # Whether rule is enabled
  prefix  = optional(string)                 # Object key prefix filter
  tags    = optional(map(string))            # Tag-based filter

  # Transition rules
  transitions = optional(list(object({
    days          = number                   # Days after creation to transition
    storage_class = string                   # Target storage class
  })), [])

  # Noncurrent version transitions
  noncurrent_version_transitions = optional(list(object({
    noncurrent_days = number                 # Days after becoming noncurrent
    storage_class   = string                 # Target storage class
  })), [])

  # Expiration
  expiration = optional(object({
    days                         = optional(number)
    expired_object_delete_marker = optional(bool)
  }))

  # Noncurrent version expiration
  noncurrent_version_expiration = optional(object({
    noncurrent_days           = number
    newer_noncurrent_versions = optional(number)
  }))

  # Abort incomplete multipart uploads
  abort_incomplete_multipart_upload_days = optional(number)
}))
```

### 1.9 Bucket Policy Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `bucket_policy` | `string` | No | `null` | Valid JSON | Custom bucket policy JSON (merged with HTTPS enforcement) |

### 1.10 Object Ownership Configuration

| Variable | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| `object_ownership` | `string` | No | `"BucketOwnerEnforced"` | One of: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter | Object ownership setting |

---

## 2. Output Variables

### 2.1 Bucket Identifiers

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `bucket_id` | `string` | No | The name of the bucket |
| `bucket_arn` | `string` | No | The ARN of the bucket |

### 2.2 Bucket Endpoints

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `bucket_domain_name` | `string` | No | The bucket domain name (bucketname.s3.amazonaws.com) |
| `bucket_regional_domain_name` | `string` | No | The bucket region-specific domain name |
| `bucket_hosted_zone_id` | `string` | No | The Route 53 Hosted Zone ID for the bucket region |
| `bucket_region` | `string` | No | The AWS region the bucket resides in |

### 2.3 Website Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `website_endpoint` | `string` | No | The website endpoint (if website hosting enabled) |
| `website_domain` | `string` | No | The domain of the website endpoint |

### 2.4 KMS Key Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `kms_key_arn` | `string` | No | The ARN of the KMS key (if created) |
| `kms_key_id` | `string` | No | The ID of the KMS key (if created) |

### 2.5 Configuration Status Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `logging_target_bucket` | `string` | No | The logging target bucket name |
| `versioning_status` | `string` | No | The versioning state of the bucket |

---

## 3. Resource Relationships

### 3.1 Resource Dependency Graph

```
                     aws_kms_key (optional)
                            |
                            v
                     aws_s3_bucket
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
aws_s3_bucket_      aws_s3_bucket_      aws_s3_bucket_
ownership_controls  versioning          server_side_encryption_
        |                   |           configuration
        |                   |                   |
        |                   v                   |
        |           aws_s3_bucket_              |
        |           lifecycle_configuration     |
        |                   |                   |
        v                   v                   v
aws_s3_bucket_      aws_s3_bucket_      aws_s3_bucket_
public_access_block logging             website_configuration
        |                                       |
        v                                       v
aws_s3_bucket_policy                    aws_s3_bucket_
        |                               cors_configuration
        v
(HTTPS enforcement + custom policy + website policy)
```

### 3.2 Resource Creation Order

| Order | Resource | Depends On | Condition |
|-------|----------|------------|-----------|
| 1 | `aws_kms_key` | - | `encryption_type == "KMS" && kms_key_arn == null` |
| 2 | `aws_s3_bucket` | `aws_kms_key` (if created) | Always |
| 3 | `aws_s3_bucket_ownership_controls` | `aws_s3_bucket` | Always |
| 4 | `aws_s3_bucket_versioning` | `aws_s3_bucket` | Always |
| 5 | `aws_s3_bucket_server_side_encryption_configuration` | `aws_s3_bucket`, `aws_kms_key` | Always |
| 6 | `aws_s3_bucket_public_access_block` | `aws_s3_bucket` | Always |
| 7 | `aws_s3_bucket_logging` | `aws_s3_bucket` | `enable_logging == true` |
| 8 | `aws_s3_bucket_lifecycle_configuration` | `aws_s3_bucket`, `aws_s3_bucket_versioning` | `length(lifecycle_rules) > 0` |
| 9 | `aws_s3_bucket_website_configuration` | `aws_s3_bucket` | `enable_website == true` |
| 10 | `aws_s3_bucket_cors_configuration` | `aws_s3_bucket` | `length(cors_rules) > 0` |
| 11 | `aws_s3_bucket_policy` | `aws_s3_bucket`, `aws_s3_bucket_public_access_block` | Always (HTTPS enforcement) |

### 3.3 Data Sources

| Data Source | Purpose | Condition |
|-------------|---------|-----------|
| `aws_caller_identity.current` | Get current account ID for KMS key policy | `encryption_type == "KMS"` |
| `aws_s3_bucket.logging_target` | Validate logging target bucket exists | `enable_logging == true` |
| `aws_iam_policy_document.kms_key_policy` | Generate KMS key policy | `encryption_type == "KMS" && kms_key_arn == null` |
| `aws_iam_policy_document.bucket_policy` | Combine HTTPS + custom + website policies | Always |

---

## 4. State Considerations

### 4.1 State Structure

```
module.s3_bucket
├── aws_kms_key.this[0] (conditional)
├── aws_s3_bucket.this
├── aws_s3_bucket_ownership_controls.this
├── aws_s3_bucket_versioning.this
├── aws_s3_bucket_server_side_encryption_configuration.this
├── aws_s3_bucket_public_access_block.this
├── aws_s3_bucket_logging.this[0] (conditional)
├── aws_s3_bucket_lifecycle_configuration.this[0] (conditional)
├── aws_s3_bucket_website_configuration.this[0] (conditional)
├── aws_s3_bucket_cors_configuration.this[0] (conditional)
└── aws_s3_bucket_policy.this
```

### 4.2 State Import Considerations

Each resource can be imported independently:

```bash
# Import bucket
terraform import 'module.s3_bucket.aws_s3_bucket.this' bucket-name

# Import versioning
terraform import 'module.s3_bucket.aws_s3_bucket_versioning.this' bucket-name

# Import encryption
terraform import 'module.s3_bucket.aws_s3_bucket_server_side_encryption_configuration.this' bucket-name

# Import public access block
terraform import 'module.s3_bucket.aws_s3_bucket_public_access_block.this' bucket-name

# Import lifecycle (if exists)
terraform import 'module.s3_bucket.aws_s3_bucket_lifecycle_configuration.this[0]' bucket-name

# Import website (if exists)
terraform import 'module.s3_bucket.aws_s3_bucket_website_configuration.this[0]' bucket-name
```

### 4.3 Drift Detection

Resources with potential drift concerns:
- `aws_s3_bucket_policy` - External policy changes
- `aws_s3_bucket_lifecycle_configuration` - Manual console changes
- `aws_kms_key` - Key policy modifications

---

## 5. Validation Rules

### 5.1 Variable Validation Blocks

```hcl
# Bucket name validation
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = null

  validation {
    condition = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase, start/end with letter or number."
  }
}

# Encryption type validation
variable "encryption_type" {
  type        = string
  description = "Encryption type: AES256 or KMS"
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either 'AES256' or 'KMS'."
  }
}

# KMS key deletion window validation
variable "kms_key_deletion_window" {
  type        = number
  description = "Days before KMS key deletion (7-30)"
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "kms_key_deletion_window must be between 7 and 30 days."
  }
}

# Lifecycle rules count validation
variable "lifecycle_rules" {
  type        = list(any)
  description = "Lifecycle rules (max 50)"
  default     = []

  validation {
    condition     = length(var.lifecycle_rules) <= 50
    error_message = "Maximum 50 lifecycle rules allowed per bucket."
  }
}

# CORS rules count validation
variable "cors_rules" {
  type        = list(any)
  description = "CORS rules (max 10)"
  default     = []

  validation {
    condition     = length(var.cors_rules) <= 10
    error_message = "Maximum 10 CORS rules allowed per bucket."
  }
}

# Environment validation
variable "environment" {
  type        = string
  description = "Environment tag"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}
```

### 5.2 Precondition Checks

```hcl
# Logging target bucket must be specified when logging is enabled
resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.logging_target_bucket != null
      error_message = "logging_target_bucket must be specified when enable_logging is true."
    }
  }
}

# Website config requires appropriate public access settings
resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_website ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.block_public_policy || var.enable_website
      error_message = "Website hosting requires block_public_policy to be false."
    }
  }
}
```

---

## 6. Complex Type Definitions

### 6.1 Full CORS Rule Type

```hcl
variable "cors_rules" {
  description = <<-EOT
    List of CORS rule configurations (max 10).
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
    error_message = "Maximum 10 CORS rules allowed."
  }
}
```

### 6.2 Full Lifecycle Rule Type

```hcl
variable "lifecycle_rules" {
  description = <<-EOT
    List of lifecycle rule configurations (max 50).
    Supports transitions, noncurrent version handling, and expiration.

    Example:
    lifecycle_rules = [
      {
        id      = "archive-to-glacier"
        enabled = true
        prefix  = "logs/"
        transitions = [
          { days = 30, storage_class = "STANDARD_IA" },
          { days = 90, storage_class = "GLACIER" }
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
    error_message = "Maximum 50 lifecycle rules allowed."
  }
}
```

---

## 7. Locals Computation

```hcl
locals {
  # Bucket name resolution
  bucket_name = var.bucket_name != null ? var.bucket_name : null

  # Determine if KMS key should be created
  create_kms_key = var.encryption_type == "KMS" && var.kms_key_arn == null

  # KMS key ARN to use (created or provided)
  kms_key_arn = local.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_arn

  # SSE algorithm based on encryption type
  sse_algorithm = var.encryption_type == "KMS" ? "aws:kms" : "AES256"

  # Website public access settings (relax when website is enabled)
  website_block_public_policy     = var.enable_website ? false : var.block_public_policy
  website_restrict_public_buckets = var.enable_website ? false : var.restrict_public_buckets

  # Common tags
  common_tags = merge(
    {
      Name        = local.bucket_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}
```

---

## 8. KMS Key Policy Structure

When KMS encryption is selected and a new key is created, the following policy structure is applied:

```hcl
data "aws_iam_policy_document" "kms_key_policy" {
  count = local.create_kms_key ? 1 : 0

  # Allow account root full access for key administration
  statement {
    sid       = "AllowRootAccountFullAccess"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow IAM principals to use the key via IAM policies
  statement {
    sid       = "AllowAccessViaIAMPolicies"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
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

  # Optional: Allow admin role to manage the key
  dynamic "statement" {
    for_each = var.kms_admin_role_arn != null ? [1] : []
    content {
      sid       = "AllowKeyAdministration"
      effect    = "Allow"
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
        "kms:CancelKeyDeletion"
      ]
      resources = ["*"]
    }
  }
}
```

---

## 9. Bucket Policy Composition

### HTTPS Enforcement Policy (Always Applied)

```hcl
data "aws_iam_policy_document" "require_https" {
  statement {
    sid       = "DenyNonHTTPS"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
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
```

### Website Public Read Policy (Conditional)

```hcl
data "aws_iam_policy_document" "website_public" {
  count = var.enable_website ? 1 : 0

  statement {
    sid       = "AllowPublicRead"
    effect    = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}
```

### Combined Policy Document

```hcl
data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact([
    data.aws_iam_policy_document.require_https.json,
    var.enable_website ? data.aws_iam_policy_document.website_public[0].json : null,
    var.bucket_policy
  ])
}
```

---

## 10. Error Messages Reference

| Validation | Error Message |
|------------|---------------|
| Bucket name format | "Bucket name must be 3-63 characters, lowercase, start/end with letter or number." |
| Encryption type | "encryption_type must be either 'AES256' or 'KMS'." |
| KMS deletion window | "kms_key_deletion_window must be between 7 and 30 days." |
| Lifecycle rules count | "Maximum 50 lifecycle rules allowed per bucket." |
| CORS rules count | "Maximum 10 CORS rules allowed per bucket." |
| Environment value | "environment must be one of: dev, staging, prod." |
| Logging target bucket | "logging_target_bucket must be specified when enable_logging is true." |
