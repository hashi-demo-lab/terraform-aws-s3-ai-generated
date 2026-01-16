# terraform-aws-s3

A production-ready Terraform module for provisioning secure AWS S3 buckets with security-first defaults.

## Features

- **Encryption at Rest**: SSE-KMS encryption with module-managed or bring-your-own KMS key
- **Encryption in Transit**: HTTPS-only bucket policy enforced by default
- **Public Access Blocking**: All public access blocked by default (CIS AWS Benchmark compliant)
- **Versioning**: Enabled by default for data protection
- **Access Logging**: Optional server access logging for compliance
- **Lifecycle Management**: Flexible lifecycle rules for cost optimization
- **Static Website Hosting**: Optional website hosting with explicit public access opt-in

## Security Considerations

This module implements secure-by-default configurations:

- **KMS Encryption**: All objects encrypted with SSE-KMS (aws:kms algorithm) and bucket keys enabled for cost efficiency
- **HTTPS Only**: Bucket policy denies all non-HTTPS requests
- **Encryption Enforcement**: Bucket policy denies uploads without proper encryption headers
- **Public Access Blocked**: All four public access block settings enabled by default
- **Ownership Controls**: BucketOwnerEnforced prevents ACL-based access patterns
- **Key Rotation**: Module-created KMS keys have automatic annual rotation enabled

### Account-Level Public Access Blocks

This module configures bucket-level public access blocks. For complete protection, also configure account-level S3 public access blocks per CIS AWS Foundations Benchmark 2.1.4:

```bash
aws s3control put-public-access-block \
    --account-id $(aws sts get-caller-identity --query Account --output text) \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### CloudTrail Data Events

For comprehensive audit logging, enable CloudTrail data events for S3:

```hcl
resource "aws_cloudtrail" "s3_data_events" {
  name           = "s3-data-events"
  s3_bucket_name = "your-cloudtrail-bucket"

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${module.s3_bucket.bucket_id}/"]
    }
  }
}
```

## Usage

### Basic Secure Bucket (Recommended)

```hcl
module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name = "my-secure-bucket"
  environment = "prod"
}
```

This creates a bucket with:
- KMS encryption (module creates and manages the key)
- Versioning enabled
- All public access blocked
- HTTPS-only access enforced

### With Existing KMS Key (BYOK)

```hcl
module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name = "my-secure-bucket"
  environment = "prod"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}
```

### With Access Logging

```hcl
# First, create or reference a logging bucket with appropriate permissions
resource "aws_s3_bucket" "logs" {
  bucket = "my-logging-bucket"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

# Then create the bucket with logging enabled
module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name    = "my-secure-bucket"
  environment    = "prod"
  enable_logging = true
  logging_bucket = aws_s3_bucket.logs.id
  logging_prefix = "s3-access-logs/"
}
```

### With Lifecycle Rules

```hcl
module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name = "my-data-lake-bucket"
  environment = "prod"

  lifecycle_rules = [
    {
      id      = "archive-old-data"
      enabled = true
      prefix  = "data/"

      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }

      abort_incomplete_multipart_upload_days = 7
    }
  ]
}
```

### Static Website Hosting

**Warning**: Website hosting requires disabling public access blocks. Only use for intentionally public content.

```hcl
module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name = "my-website-bucket"
  environment = "prod"

  # Must explicitly disable all public access blocks
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  website_configuration = {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# Add public read policy for website content
resource "aws_s3_bucket_policy" "website" {
  bucket = module.s3_bucket.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.s3_bucket.bucket_arn}/*"
      }
    ]
  })

  depends_on = [module.s3_bucket]
}
```

## Compliance Mapping

| Control | Framework | Implementation |
|---------|-----------|----------------|
| Encryption at rest | CIS 2.1.1, SOC 2 | SSE-KMS with bucket keys |
| Access logging | CIS 2.1.2, SOC 2 | Optional server access logging |
| HTTPS only | CIS 2.1.5, SOC 2 | Bucket policy condition |
| Public access blocked | CIS 2.1.5 | Public access block settings |
| Versioning | SOC 2 | Enabled by default |

## Troubleshooting

### Error: Bucket name already exists

S3 bucket names are globally unique. Use a random suffix:

```hcl
resource "random_id" "suffix" {
  byte_length = 4
}

module "s3_bucket" {
  source = "path/to/terraform-aws-s3"

  bucket_name = "my-bucket-${random_id.suffix.hex}"
  environment = "prod"
}
```

### Error: Access Denied when creating KMS key

Ensure your IAM user/role has KMS permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "kms:CreateKey",
    "kms:CreateAlias",
    "kms:TagResource",
    "kms:DescribeKey"
  ],
  "Resource": "*"
}
```

### Error: logging_bucket is required

When `enable_logging = true`, you must provide a valid logging bucket:

```hcl
enable_logging = true
logging_bucket = "my-existing-logging-bucket"
```

### Error: All public access blocks must be disabled for website

Website hosting requires explicit opt-out of security controls:

```hcl
block_public_acls       = false
block_public_policy     = false
ignore_public_acls      = false
restrict_public_buckets = false
```

<!-- BEGIN_TF_DOCS -->
# terraform-aws-s3-module

## Usage

### Basic Usage - Secure Bucket (Default)

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name      = "my-secure-bucket-12345"
  application_name = "my-application"
  environment      = "dev"
}
```

### KMS Encryption

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name             = "my-kms-encrypted-bucket"
  application_name        = "my-application"
  environment             = "prod"
  encryption_type         = "KMS"
  enable_kms_key_rotation = true
}
```

### Static Website Hosting

```hcl
module "website_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name            = "my-website-bucket"
  application_name       = "my-website"
  environment            = "prod"
  enable_website         = true
  website_index_document = "index.html"
  website_error_document = "error.html"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Unique name for the S3 bucket. Must be globally unique across all AWS accounts. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment identifier (e.g., dev, staging, prod). Used for tagging. | `string` | n/a | yes |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Block public ACL creation on the bucket. Set to false only for static website hosting. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Block public bucket policy attachment. Set to false only for static website hosting. | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable server access logging. Requires logging\_bucket to be specified when true. | `bool` | `false` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable bucket versioning for object version management and data protection. WARNING: Once enabled, versioning can only be suspended, not disabled. Suspending versioning does not delete existing versions. | `bool` | `true` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Ignore existing public ACLs on the bucket. Set to false only for static website hosting. | `bool` | `true` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | Waiting period in days before KMS key deletion. Only applies when module creates the KMS key. Minimum 7 days, maximum 30 days. | `number` | `30` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of an existing KMS key for bucket encryption. If not provided, the module creates a new KMS key. | `string` | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Lifecycle rules for object transitions and expiration. Supports storage class transitions, expiration, and noncurrent version management. | <pre>list(object({<br/>    id      = string<br/>    enabled = optional(bool, true)<br/>    prefix  = optional(string, "")<br/>    tags    = optional(map(string), {})<br/><br/>    transitions = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/><br/>    expiration = optional(object({<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool, false)<br/>    }))<br/><br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days = number<br/>      storage_class   = string<br/>    })), [])<br/><br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/><br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | Name of the target bucket for server access logs. Must exist and have appropriate permissions (log-delivery-write ACL). | `string` | `null` | no |
| <a name="input_logging_prefix"></a> [logging\_prefix](#input\_logging\_prefix) | Prefix for log object keys in the logging bucket. | `string` | `"logs/"` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Restrict public bucket policies. Set to false only for static website hosting. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. Merged with default module tags (environment, managed\_by, module). | `map(string)` | `{}` | no |
| <a name="input_website_configuration"></a> [website\_configuration](#input\_website\_configuration) | Static website hosting configuration. Requires all public access blocks to be disabled (block\_public\_acls, block\_public\_policy, ignore\_public\_acls, restrict\_public\_buckets must all be false). | <pre>object({<br/>    index_document = string<br/>    error_document = optional(string, "error.html")<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name (bucket.s3.amazonaws.com) |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The name of the bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name (bucket.s3.region.amazonaws.com) |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key used for bucket encryption |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key used for bucket encryption |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | Website domain for DNS configuration (only when website hosting is enabled) |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | Website endpoint URL (only when website hosting is enabled) |

<!-- END_TF_DOCS -->

## Examples

- [Basic](./examples/basic) - Minimal secure bucket with defaults
- [Complete](./examples/complete) - All optional features demonstrated

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE) for full details.
