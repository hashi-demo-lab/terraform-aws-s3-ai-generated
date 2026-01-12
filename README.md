# terraform-aws-s3-module

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.70.0, < 6.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [random_id.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.require_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.require_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.website_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.logging_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of the application using this bucket. Required for AWS-TAG-001 compliance. | `string` | n/a | yes |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Block public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Block public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket (must be globally unique). Either bucket\_name or bucket\_prefix must be provided. | `string` | `null` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | Custom bucket policy JSON. Will be merged with HTTPS enforcement policy. | `string` | `null` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix for bucket name with random suffix for uniqueness. Max 37 characters. Conflicts with bucket\_name. | `string` | `null` | no |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | List of CORS rule configurations (max 10 rules).<br/>Each rule specifies allowed origins, methods, headers, and caching behavior.<br/><br/>Example:<br/>cors\_rules = [<br/>  {<br/>    id              = "allow-website"<br/>    allowed\_headers = ["*"]<br/>    allowed\_methods = ["GET", "HEAD"]<br/>    allowed\_origins = ["https://example.com"]<br/>    expose\_headers  = ["ETag"]<br/>    max\_age\_seconds = 3000<br/>  }<br/>] | <pre>list(object({<br/>    id              = optional(string)<br/>    allowed_headers = optional(list(string), [])<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    expose_headers  = optional(list(string), [])<br/>    max_age_seconds = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_enable_kms_key_rotation"></a> [enable\_kms\_key\_rotation](#input\_enable\_kms\_key\_rotation) | Enable automatic annual KMS key rotation. | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable server access logging for the bucket. | `bool` | `false` | no |
| <a name="input_enable_mfa_delete"></a> [enable\_mfa\_delete](#input\_enable\_mfa\_delete) | Enable MFA delete for versioned objects. Requires versioning to be enabled. | `bool` | `false` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable versioning on the bucket. Recommended for data protection. | `bool` | `true` | no |
| <a name="input_enable_website"></a> [enable\_website](#input\_enable\_website) | Enable static website hosting for the bucket. | `bool` | `false` | no |
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | Server-side encryption type: AES256 (SSE-S3) or KMS (SSE-KMS). | `string` | `"AES256"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment tag value (dev, staging, prod). | `string` | `"dev"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow bucket deletion with objects inside. Use with caution in production. | `bool` | `false` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Ignore public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_kms_admin_role_arn"></a> [kms\_admin\_role\_arn](#input\_kms\_admin\_role\_arn) | ARN of IAM role granted KMS key administration permissions. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of existing KMS key for SSE-KMS. If null and encryption\_type is KMS, a new key is created. | `string` | `null` | no |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | Days before KMS key deletion (7-30 days). | `number` | `30` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rule configurations (max 50 rules).<br/>Supports transitions to various storage classes and expiration.<br/><br/>Valid storage classes: STANDARD\_IA, INTELLIGENT\_TIERING, GLACIER\_IR, GLACIER, DEEP\_ARCHIVE<br/><br/>Example:<br/>lifecycle\_rules = [<br/>  {<br/>    id      = "archive-old-data"<br/>    enabled = true<br/>    prefix  = "logs/"<br/>    transitions = [<br/>      { days = 30,  storage\_class = "STANDARD\_IA" },<br/>      { days = 90,  storage\_class = "GLACIER" }<br/>    ]<br/>    expiration = { days = 365 }<br/>    noncurrent\_version\_expiration = { noncurrent\_days = 30 }<br/>  }<br/>] | <pre>list(object({<br/>    id      = string<br/>    enabled = optional(bool, true)<br/>    prefix  = optional(string)<br/>    tags    = optional(map(string))<br/><br/>    transitions = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/><br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days = number<br/>      storage_class   = string<br/>    })), [])<br/><br/>    expiration = optional(object({<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/><br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/><br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_logging_target_bucket"></a> [logging\_target\_bucket](#input\_logging\_target\_bucket) | Target bucket for access logs. Required when enable\_logging is true. | `string` | `null` | no |
| <a name="input_logging_target_prefix"></a> [logging\_target\_prefix](#input\_logging\_target\_prefix) | Prefix for log objects in the target bucket. | `string` | `"logs/"` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | Object ownership setting. BucketOwnerEnforced disables ACLs. | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Restrict public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_website_error_document"></a> [website\_error\_document](#input\_website\_error\_document) | Error document for static website hosting. | `string` | `"error.html"` | no |
| <a name="input_website_index_document"></a> [website\_index\_document](#input\_website\_index\_document) | Index document for static website hosting. | `string` | `"index.html"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name (format: bucketname.s3.amazonaws.com). |
| <a name="output_bucket_hosted_zone_id"></a> [bucket\_hosted\_zone\_id](#output\_bucket\_hosted\_zone\_id) | The Route 53 Hosted Zone ID for the bucket region. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The name of the bucket. |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | The AWS region the bucket resides in. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The bucket region-specific domain name. |
| <a name="output_effective_public_access_block"></a> [effective\_public\_access\_block](#output\_effective\_public\_access\_block) | The effective public access block settings applied to the bucket. |
| <a name="output_encryption_type"></a> [encryption\_type](#output\_encryption\_type) | The encryption type configured for the bucket (AES256 or KMS). |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key (if created by this module). |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The ID of the KMS key (if created by this module). |
| <a name="output_logging_target_bucket"></a> [logging\_target\_bucket](#output\_logging\_target\_bucket) | The logging target bucket name (if logging is enabled). |
| <a name="output_versioning_status"></a> [versioning\_status](#output\_versioning\_status) | The versioning state of the bucket (Enabled or Suspended). |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | The domain of the website endpoint (if static website hosting is enabled). |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | The website endpoint (if static website hosting is enabled). |

<!-- END_TF_DOCS -->

