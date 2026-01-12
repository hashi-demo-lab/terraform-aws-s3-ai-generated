# Complete Data Lake Example

This example demonstrates a full-featured data lake configuration with:

- KMS encryption
- Server access logging
- Comprehensive lifecycle policies
- Cost optimization through storage tiering

## Architecture

This example creates two buckets:

1. **Logging Bucket**: Receives access logs from the data lake bucket
2. **Data Lake Bucket**: Main storage with full security and lifecycle features

## Features

### Security Features

- KMS encryption with automatic key rotation
- Versioning enabled for data protection
- All public access blocks enabled
- HTTPS enforcement via bucket policy
- Encryption enforcement via bucket policy

### Cost Optimization Features

- Lifecycle rules for automatic storage tiering
- Transition to STANDARD_IA, GLACIER_IR, GLACIER, DEEP_ARCHIVE
- Automatic expiration of old data
- Noncurrent version cleanup
- Abort incomplete multipart uploads

### Operational Features

- Server access logging
- Comprehensive tagging
- Environment-based configuration

## Usage

```hcl
module "datalake" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_prefix    = "datalake-myapp"
  application_name = "my-data-platform"
  environment      = "prod"

  encryption_type         = "KMS"
  enable_kms_key_rotation = true

  lifecycle_rules = [
    {
      id      = "archive-raw-data"
      enabled = true
      prefix  = "raw/"
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" }
      ]
      expiration = { days = 365 }
    }
  ]

  tags = {
    Project    = "DataPlatform"
    CostCenter = "Analytics"
  }
}
```

## Quick Start

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Create a `terraform.tfvars` file:

   ```hcl
   application_name = "my-data-platform"
   environment      = "prod"
   ```

3. Apply the configuration:

   ```bash
   terraform plan
   terraform apply
   ```

## Lifecycle Rules Explained

### Raw Data Tiering

Objects in the `raw/` prefix transition through storage classes:

| Days | Storage Class | Use Case |
|------|---------------|----------|
| 0-29 | STANDARD | Active processing |
| 30-89 | STANDARD_IA | Less frequent access |
| 90-179 | GLACIER_IR | Instant retrieval archives |
| 180-364 | GLACIER | Flexible retrieval (minutes to hours) |
| 365+ | DEEP_ARCHIVE | Long-term archives (12+ hours) |

### Processed Data

Objects in the `processed/` prefix:

- Move to INTELLIGENT_TIERING after 60 days
- Expire after 2 years (730 days)

### Temporary Data

Objects in the `temp/` prefix:

- Automatically deleted after 7 days

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| application_name | Name of the application | string | - | yes |
| environment | Environment | string | "prod" | no |
| lifecycle_rules | Lifecycle rules | list(object) | [...] | no |
| cors_rules | CORS rules | list(object) | [] | no |
| tags | Additional tags | map(string) | {...} | no |

## Outputs

| Name | Description |
|------|-------------|
| datalake_bucket_id | The name of the data lake bucket |
| datalake_bucket_arn | The ARN of the data lake bucket |
| kms_key_arn | The ARN of the KMS key |
| logging_bucket_id | The name of the logging bucket |
| versioning_status | The versioning status |
| encryption_type | The encryption type (KMS) |

## Cost Considerations

### Storage Class Pricing (US East 1 as of 2024)

| Storage Class | Price/GB/Month | Retrieval Cost |
|---------------|---------------|----------------|
| STANDARD | $0.023 | None |
| STANDARD_IA | $0.0125 | $0.01/GB |
| INTELLIGENT_TIERING | $0.023-$0.0025 | None |
| GLACIER_IR | $0.004 | $0.03/GB |
| GLACIER | $0.004 | $0.01-$0.03/GB |
| DEEP_ARCHIVE | $0.00099 | $0.02-$0.05/GB |

### Estimated Savings

For a typical data lake with 1TB of raw data:

- **Without lifecycle**: ~$23/month
- **With lifecycle (after 1 year)**: ~$5/month
- **Savings**: ~78%

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.70.0, < 6.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_datalake_bucket"></a> [datalake\_bucket](#module\_datalake\_bucket) | ../../ | n/a |
| <a name="module_logging_bucket"></a> [logging\_bucket](#module\_logging\_bucket) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of the application using this bucket | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | CORS rules for the data lake bucket | <pre>list(object({<br/>    id              = optional(string)<br/>    allowed_headers = optional(list(string), [])<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    expose_headers  = optional(list(string), [])<br/>    max_age_seconds = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (dev, staging, prod) | `string` | `"prod"` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Lifecycle rules for the data lake bucket | <pre>list(object({<br/>    id      = string<br/>    enabled = optional(bool, true)<br/>    prefix  = optional(string)<br/>    tags    = optional(map(string))<br/>    transitions = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days = number<br/>      storage_class   = string<br/>    })), [])<br/>    expiration = optional(object({<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "abort_incomplete_multipart_upload_days": 7,<br/>    "enabled": true,<br/>    "id": "raw-data-tiering",<br/>    "noncurrent_version_expiration": {<br/>      "noncurrent_days": 30<br/>    },<br/>    "prefix": "raw/",<br/>    "transitions": [<br/>      {<br/>        "days": 30,<br/>        "storage_class": "STANDARD_IA"<br/>      },<br/>      {<br/>        "days": 90,<br/>        "storage_class": "GLACIER_IR"<br/>      },<br/>      {<br/>        "days": 180,<br/>        "storage_class": "GLACIER"<br/>      },<br/>      {<br/>        "days": 365,<br/>        "storage_class": "DEEP_ARCHIVE"<br/>      }<br/>    ]<br/>  },<br/>  {<br/>    "enabled": true,<br/>    "expiration": {<br/>      "days": 730<br/>    },<br/>    "id": "processed-data-tiering",<br/>    "prefix": "processed/",<br/>    "transitions": [<br/>      {<br/>        "days": 60,<br/>        "storage_class": "INTELLIGENT_TIERING"<br/>      }<br/>    ]<br/>  },<br/>  {<br/>    "enabled": true,<br/>    "expiration": {<br/>      "days": 7<br/>    },<br/>    "id": "temp-cleanup",<br/>    "prefix": "temp/"<br/>  }<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply | `map(string)` | <pre>{<br/>  "CostCenter": "Analytics",<br/>  "Project": "DataPlatform"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_datalake_bucket_arn"></a> [datalake\_bucket\_arn](#output\_datalake\_bucket\_arn) | The ARN of the data lake bucket |
| <a name="output_datalake_bucket_domain_name"></a> [datalake\_bucket\_domain\_name](#output\_datalake\_bucket\_domain\_name) | The domain name of the data lake bucket |
| <a name="output_datalake_bucket_id"></a> [datalake\_bucket\_id](#output\_datalake\_bucket\_id) | The name of the data lake bucket |
| <a name="output_datalake_bucket_regional_domain_name"></a> [datalake\_bucket\_regional\_domain\_name](#output\_datalake\_bucket\_regional\_domain\_name) | The regional domain name of the data lake bucket |
| <a name="output_encryption_type"></a> [encryption\_type](#output\_encryption\_type) | The encryption type of the data lake bucket |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used for encryption |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The ID of the KMS key |
| <a name="output_logging_bucket_arn"></a> [logging\_bucket\_arn](#output\_logging\_bucket\_arn) | The ARN of the logging bucket |
| <a name="output_logging_bucket_id"></a> [logging\_bucket\_id](#output\_logging\_bucket\_id) | The name of the logging bucket |
| <a name="output_logging_target_bucket"></a> [logging\_target\_bucket](#output\_logging\_target\_bucket) | The logging target bucket |
| <a name="output_versioning_status"></a> [versioning\_status](#output\_versioning\_status) | The versioning status of the data lake bucket |
<!-- END_TF_DOCS -->

