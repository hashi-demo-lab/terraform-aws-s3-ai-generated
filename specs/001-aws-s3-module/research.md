# Research: Terraform AWS S3 Module

**Feature**: terraform-aws-s3-module
**Date**: 2026-01-11
**Status**: Complete

## Overview

This document consolidates research findings for implementing a comprehensive AWS S3 module supporting secure bucket deployment, static website hosting, and data lake storage with lifecycle policies.

---

## 1. AWS Provider Version and Compatibility

### Decision
Use AWS Provider version `~> 5.0` with minimum version `5.0.0`.

### Rationale
- The latest AWS provider version is `6.28.0` but specification requires `~> 5.0` for broader compatibility
- AWS Provider 5.x introduced significant changes to S3 resource structure (separate configuration resources)
- Provider 5.x uses individual resources for S3 configurations instead of deprecated inline blocks
- Ensures compatibility with existing infrastructure and avoids breaking changes

### Alternatives Considered
- **Provider 4.x**: Rejected - uses deprecated inline configuration blocks in `aws_s3_bucket` resource
- **Provider 6.x**: Could be used but specification explicitly requires `~> 5.0`

---

## 2. S3 Resource Architecture (Provider 5.x+)

### Decision
Use separate configuration resources instead of inline blocks on the `aws_s3_bucket` resource.

### Rationale
AWS Provider 5.x deprecates inline configuration blocks on `aws_s3_bucket`. The following separate resources must be used:

| Configuration | Deprecated Inline | Required Resource |
|--------------|-------------------|-------------------|
| Versioning | `versioning {}` | `aws_s3_bucket_versioning` |
| Encryption | `server_side_encryption_configuration {}` | `aws_s3_bucket_server_side_encryption_configuration` |
| Public Access | N/A | `aws_s3_bucket_public_access_block` |
| Lifecycle | `lifecycle_rule {}` | `aws_s3_bucket_lifecycle_configuration` |
| Website | `website {}` | `aws_s3_bucket_website_configuration` |
| CORS | `cors_rule {}` | `aws_s3_bucket_cors_configuration` |
| Logging | `logging {}` | `aws_s3_bucket_logging` |
| Policy | `policy` | `aws_s3_bucket_policy` |
| Ownership | N/A | `aws_s3_bucket_ownership_controls` |

### Key Findings from Provider Documentation

1. **aws_s3_bucket**: Core resource with minimal configuration (bucket name, tags, force_destroy, object_lock_enabled)
2. **aws_s3_bucket_versioning**: Supports `Enabled`, `Suspended`, or `Disabled` status; MFA delete optional
3. **aws_s3_bucket_server_side_encryption_configuration**: Supports `AES256`, `aws:kms`, and `aws:kms:dsse` algorithms; bucket_key_enabled for cost optimization
4. **aws_s3_bucket_public_access_block**: Four independent boolean settings for comprehensive public access control
5. **aws_s3_bucket_lifecycle_configuration**: Supports transitions to `GLACIER`, `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `DEEP_ARCHIVE`, `GLACIER_IR`
6. **aws_s3_bucket_website_configuration**: Requires index_document or redirect_all_requests_to
7. **aws_s3_bucket_cors_configuration**: Supports up to 100 rules (spec limits to 10)
8. **aws_s3_bucket_ownership_controls**: Required for `BucketOwnerEnforced` to disable ACLs

---

## 3. KMS Key Configuration

### Decision
Create a dedicated KMS key with automatic rotation when SSE-KMS encryption is selected.

### Rationale
- Dedicated KMS keys provide better security isolation and audit trails
- Automatic key rotation (annual) required by CIS AWS Benchmark
- Key policy must allow account root and configurable admin role

### Key Configuration
```hcl
resource "aws_kms_key" "this" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = var.kms_key_deletion_window  # 7-30 days
  enable_key_rotation     = var.enable_kms_key_rotation  # default: true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}
```

### Key Policy Requirements (from spec SR-005)
- Allow AWS account root for key administration
- Allow IAM principals via IAM policies for key usage
- Allow configurable admin role ARN (optional) for key management delegation

---

## 4. Bucket Policy for HTTPS Enforcement

### Decision
Implement bucket policy that denies non-HTTPS requests by default.

### Rationale
- Required by CIS AWS Benchmark 2.1.1
- Enforces encryption in transit
- Uses `aws:SecureTransport` condition

### Implementation
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

---

## 5. Website Hosting Configuration

### Decision
When website hosting is enabled, selectively disable public access blocks and create appropriate bucket policy.

### Rationale
- Website hosting requires public read access
- Must relax specific public access blocks while maintaining other security controls
- Bucket policy should only allow GetObject for website content

### Configuration Requirements
1. Set `block_public_acls = true` (keep enabled)
2. Set `ignore_public_acls = true` (keep enabled)
3. Set `block_public_policy = false` (must disable for website policy)
4. Set `restrict_public_buckets = false` (must disable for public access)
5. Create bucket policy allowing public `s3:GetObject`

---

## 6. Lifecycle Configuration Storage Classes

### Decision
Support all Glacier storage classes and Intelligent-Tiering as specified in requirements.

### Rationale
- Provides flexibility for different data retention strategies
- Supports cost optimization through automated transitions

### Supported Storage Classes (from provider documentation)
| Storage Class | Use Case | Minimum Storage Duration |
|--------------|----------|-------------------------|
| `STANDARD_IA` | Infrequent access | 30 days |
| `ONEZONE_IA` | Single-AZ infrequent | 30 days |
| `INTELLIGENT_TIERING` | Unknown access patterns | N/A |
| `GLACIER_IR` | Instant retrieval archives | 90 days |
| `GLACIER` | Flexible retrieval (minutes to hours) | 90 days |
| `DEEP_ARCHIVE` | Long-term archives (12+ hours retrieval) | 180 days |

### Transition Configuration
```hcl
dynamic "transition" {
  for_each = each.value.transitions
  content {
    days          = transition.value.days
    storage_class = transition.value.storage_class
  }
}
```

---

## 7. Input Validation Strategy

### Decision
Use Terraform variable validation blocks for all constraints.

### Rationale
- Errors surface during `terraform plan` before resource evaluation
- Provides clear error messages to users
- Fails fast without making AWS API calls

### Validation Examples
```hcl
variable "bucket_name" {
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase, DNS-compliant."
  }
}

variable "lifecycle_rules" {
  validation {
    condition     = length(var.lifecycle_rules) <= 50
    error_message = "Maximum 50 lifecycle rules allowed."
  }
}

variable "cors_rules" {
  validation {
    condition     = length(var.cors_rules) <= 10
    error_message = "Maximum 10 CORS rules allowed."
  }
}
```

---

## 8. Logging Target Bucket Validation

### Decision
Use data source lookup to validate logging target bucket exists.

### Rationale
- Provides early failure during `terraform plan`
- Clear error message if bucket doesn't exist or is inaccessible
- Better user experience than runtime API errors

### Implementation
```hcl
data "aws_s3_bucket" "logging_target" {
  count  = var.enable_logging ? 1 : 0
  bucket = var.logging_target_bucket
}
```

---

## 9. Object Ownership Configuration

### Decision
Enforce `BucketOwnerEnforced` object ownership by default.

### Rationale
- Required by spec SR-006 (no bucket ACLs)
- Simplifies access management
- Aligns with AWS best practices

### Implementation
```hcl
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = var.object_ownership  # default: "BucketOwnerEnforced"
  }
}
```

---

## 10. Resource Dependencies

### Decision
Explicit dependency ordering through resource references and depends_on.

### Critical Dependencies Identified
1. `aws_s3_bucket_versioning` should be created before `aws_s3_bucket_lifecycle_configuration` (versioning must be enabled for noncurrent version rules)
2. `aws_s3_bucket_public_access_block` should be created before `aws_s3_bucket_policy` (policy may conflict with blocks)
3. `aws_kms_key` must be created before `aws_s3_bucket_server_side_encryption_configuration` (when KMS encryption selected)
4. `aws_s3_bucket_ownership_controls` should be created early (affects ACL behavior)

---

## 11. Terraform Version Compatibility

### Decision
Require Terraform >= 1.5.0

### Rationale
- Specification requires >= 1.5.0
- Ensures compatibility with modern Terraform features
- Supports import blocks and validation improvements

---

## 12. Testing Strategy

### Decision
Use Terraform Test Framework with unit and integration tests.

### Rationale
- Native Terraform testing (no external tools required)
- Supports both plan-based unit tests and apply-based integration tests
- Aligns with constitution requirements

### Test Categories
1. **Unit Tests**: Variable validation, conditional logic, defaults
2. **Integration Tests**: Actual resource creation and verification
3. **Compliance Tests**: CIS Benchmark and SOC 2 verification

---

## Summary of Key Technical Decisions

| Area | Decision | Reference |
|------|----------|-----------|
| Provider Version | `~> 5.0` | NFR-002 |
| Terraform Version | `>= 1.5.0` | NFR-001 |
| Resource Architecture | Separate configuration resources | AWS Provider 5.x |
| Encryption Default | AES-256 (SSE-S3) | FR-004, SR-001 |
| KMS Key Rotation | Enabled by default | SR-005 |
| Public Access | Blocked by default | FR-010, SR-002 |
| HTTPS Enforcement | Bucket policy with SecureTransport | SR-003 |
| Object Ownership | BucketOwnerEnforced | SR-006 |
| Validation Method | Variable validation blocks | FR-026 |
| Lifecycle Rules Max | 50 rules | FR-018a |
| CORS Rules Max | 10 rules | FR-023a |
