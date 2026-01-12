# Basic S3 Bucket Example

This example demonstrates the minimal configuration for creating a secure S3 bucket with default security settings.

## Features Enabled by Default

- AES-256 server-side encryption
- Versioning enabled
- All public access blocks enabled
- HTTPS enforcement via bucket policy
- Encryption enforcement via bucket policy

## Usage

```hcl
module "s3_bucket" {
  source = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name      = "my-secure-bucket-12345"
  application_name = "my-application"
  environment      = "dev"
}
```

## Quick Start

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Create a `terraform.tfvars` file:

   ```hcl
   bucket_name      = "my-unique-bucket-name-12345"
   application_name = "my-app"
   environment      = "dev"
   ```

3. Apply the configuration:

   ```bash
   terraform plan
   terraform apply
   ```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| application_name | Name of the application | string | - | yes |
| environment | Environment (dev, staging, prod) | string | "dev" | no |
| aws_region | AWS region | string | "us-east-1" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| versioning_status | The versioning status |
| encryption_type | The encryption type |

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
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of the application using this bucket | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket (must be globally unique) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The name of the bucket |
| <a name="output_encryption_type"></a> [encryption\_type](#output\_encryption\_type) | The encryption type |
| <a name="output_versioning_status"></a> [versioning\_status](#output\_versioning\_status) | The versioning status |
<!-- END_TF_DOCS -->

