# Quickstart Guide: Terraform AWS S3 Module

**Module**: terraform-aws-s3-module
**Version**: 1.0.0
**Date**: 2026-01-11

---

## Overview

This module creates a secure, compliant AWS S3 bucket with sensible defaults. It supports three primary use cases:

1. **Secure Bucket** - Encrypted, versioned, private bucket (default)
2. **Static Website** - Public website hosting with CORS support
3. **Data Lake** - Storage with lifecycle policies for cost optimization

---

## Prerequisites

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- AWS credentials configured
- Globally unique bucket name

---

## Basic Usage

### Minimal Configuration (Secure Bucket)

```hcl
module "s3_bucket" {
  source = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name = "my-secure-bucket-12345"
  environment = "dev"
}
```

This creates a bucket with:
- AES-256 encryption enabled
- Versioning enabled
- All public access blocked
- HTTPS enforced via bucket policy
- BucketOwnerEnforced object ownership

---

## Common Use Cases

### 1. Secure Bucket with KMS Encryption

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name             = "my-kms-encrypted-bucket"
  environment             = "prod"
  encryption_type         = "KMS"
  enable_kms_key_rotation = true
  kms_key_deletion_window = 30

  tags = {
    Project   = "DataPlatform"
    CostCenter = "Engineering"
  }
}
```

### 2. Static Website Hosting

```hcl
module "website_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name             = "my-website-bucket"
  environment             = "prod"
  enable_website          = true
  website_index_document  = "index.html"
  website_error_document  = "error.html"

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}

output "website_url" {
  value = module.website_bucket.website_endpoint
}
```

### 3. Data Lake with Lifecycle Policies

```hcl
module "datalake_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name = "my-datalake-bucket"
  environment = "prod"

  lifecycle_rules = [
    {
      id      = "archive-old-data"
      enabled = true
      prefix  = "raw-data/"

      transitions = [
        { days = 30,  storage_class = "STANDARD_IA" },
        { days = 90,  storage_class = "GLACIER" },
        { days = 365, storage_class = "DEEP_ARCHIVE" }
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    },
    {
      id      = "cleanup-temp"
      enabled = true
      prefix  = "temp/"

      expiration = {
        days = 7
      }
    }
  ]
}
```

### 4. Bucket with Access Logging

```hcl
# First, create/reference the logging target bucket
module "logging_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name = "my-logging-bucket"
  environment = "prod"
}

# Then create the bucket with logging enabled
module "main_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name           = "my-main-bucket"
  environment           = "prod"
  enable_logging        = true
  logging_target_bucket = module.logging_bucket.bucket_id
  logging_target_prefix = "access-logs/"
}
```

---

## Input Variables Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `bucket_name` | string | Name of the S3 bucket (must be globally unique) |

### Security Configuration (Defaults are secure)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_versioning` | bool | `true` | Enable versioning |
| `encryption_type` | string | `"AES256"` | Encryption type (AES256 or KMS) |
| `block_public_acls` | bool | `true` | Block public ACLs |
| `block_public_policy` | bool | `true` | Block public policies |
| `ignore_public_acls` | bool | `true` | Ignore public ACLs |
| `restrict_public_buckets` | bool | `true` | Restrict public buckets |

### Website Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_website` | bool | `false` | Enable static website hosting |
| `website_index_document` | string | `"index.html"` | Index document |
| `website_error_document` | string | `"error.html"` | Error document |
| `cors_rules` | list(object) | `[]` | CORS rules (max 10) |

### Lifecycle Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lifecycle_rules` | list(object) | `[]` | Lifecycle rules (max 50) |

---

## Output Variables Reference

| Output | Type | Description |
|--------|------|-------------|
| `bucket_id` | string | The name of the bucket |
| `bucket_arn` | string | The ARN of the bucket |
| `bucket_domain_name` | string | The bucket domain name |
| `bucket_regional_domain_name` | string | Region-specific domain name |
| `website_endpoint` | string | Website endpoint (if enabled) |
| `kms_key_arn` | string | KMS key ARN (if created) |
| `versioning_status` | string | Versioning state |

---

## Security Features

### Enabled by Default

1. **Encryption at Rest**: AES-256 (SSE-S3) encryption
2. **Encryption in Transit**: Bucket policy enforces HTTPS
3. **Versioning**: Enabled for data protection
4. **Public Access Blocked**: All four public access blocks enabled
5. **Object Ownership**: BucketOwnerEnforced (no ACLs)

### Optional Security Enhancements

1. **KMS Encryption**: Set `encryption_type = "KMS"` for customer-managed keys
2. **MFA Delete**: Set `enable_mfa_delete = true` for additional protection
3. **Access Logging**: Enable logging to audit bucket access

---

## Compliance

This module is designed to meet:

- **CIS AWS Foundations Benchmark v1.5.0**: Controls 2.1.1, 2.1.4, 2.1.5
- **SOC 2**: CC6.1, CC6.6, CC6.7, CC7.2, CC7.4

---

## Troubleshooting

### Common Issues

**1. Bucket name already exists**
```
Error: creating S3 Bucket: BucketAlreadyExists
```
Solution: S3 bucket names are globally unique. Choose a different name or use `bucket_prefix` for auto-generated names.

**2. KMS key permission denied**
```
Error: creating KMS Key: AccessDeniedException
```
Solution: Ensure your IAM role has `kms:CreateKey` and `kms:PutKeyPolicy` permissions.

**3. Logging target bucket not found**
```
Error: data.aws_s3_bucket.logging_target: bucket not found
```
Solution: Ensure the logging target bucket exists and you have permission to access it.

**4. Website hosting with public access blocks**
```
Error: conflicting public access settings
```
Solution: When `enable_website = true`, the module automatically adjusts public access blocks. No manual intervention needed.

---

## Migration from Existing Buckets

To import an existing bucket:

```bash
# Import the bucket
terraform import 'module.s3_bucket.aws_s3_bucket.this' existing-bucket-name

# Import versioning
terraform import 'module.s3_bucket.aws_s3_bucket_versioning.this' existing-bucket-name

# Import encryption
terraform import 'module.s3_bucket.aws_s3_bucket_server_side_encryption_configuration.this' existing-bucket-name

# Import public access block
terraform import 'module.s3_bucket.aws_s3_bucket_public_access_block.this' existing-bucket-name
```

---

## Support

- **Documentation**: See README.md for complete reference
- **Issues**: Report bugs via GitHub Issues
- **Questions**: Contact the Platform Team

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-11 | Initial release |
