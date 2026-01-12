# Static Website Hosting Example

This example demonstrates how to configure an S3 bucket for static website hosting with CORS support.

## Features

- Static website hosting enabled
- Index and error document configuration
- CORS rules for cross-origin access
- Automatic public access block adjustment
- HTTPS enforcement via bucket policy
- Public read access for website content

## Important Security Notes

When `enable_website = true`, the module automatically:

1. Sets `block_public_policy = false` to allow the website bucket policy
2. Sets `restrict_public_buckets = false` to allow public access
3. Keeps `block_public_acls = true` to prevent ACL-based public access
4. Creates a bucket policy allowing public `s3:GetObject` for website content

## Usage

```hcl
module "website_bucket" {
  source  = "app.terraform.io/hashi-demos-apj/s3/aws"
  version = "~> 1.0"

  bucket_name      = "my-website-bucket-12345"
  application_name = "my-website"
  environment      = "prod"

  enable_website         = true
  website_index_document = "index.html"
  website_error_document = "error.html"

  cors_rules = [
    {
      id              = "allow-all-origins"
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com", "https://www.example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
}
```

## Quick Start

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Create a `terraform.tfvars` file:

   ```hcl
   bucket_name      = "my-website-12345"
   application_name = "my-website"
   environment      = "prod"
   ```

3. Apply the configuration:

   ```bash
   terraform plan
   terraform apply
   ```

4. Upload your website files:

   ```bash
   aws s3 cp index.html s3://my-website-12345/
   aws s3 cp error.html s3://my-website-12345/
   ```

5. Access your website at the output URL.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| application_name | Name of the application | string | - | yes |
| environment | Environment | string | "prod" | no |
| website_index_document | Index document | string | "index.html" | no |
| website_error_document | Error document | string | "error.html" | no |
| cors_rules | CORS rules | list(object) | [...] | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| website_endpoint | The website endpoint URL |
| website_url | The full website URL |
| effective_public_access_block | The effective public access settings |

## CORS Configuration Examples

### Allow All Origins (Development)

```hcl
cors_rules = [
  {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
  }
]
```

### Specific Origins (Production)

```hcl
cors_rules = [
  {
    id              = "production-origins"
    allowed_headers = ["Authorization", "Content-Type"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = ["https://app.example.com", "https://api.example.com"]
    expose_headers  = ["ETag", "x-amz-meta-custom-header"]
    max_age_seconds = 86400
  }
]
```

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
| <a name="module_website_bucket"></a> [website\_bucket](#module\_website\_bucket) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of the application using this bucket | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket (must be globally unique) | `string` | n/a | yes |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | CORS rules for cross-origin access | <pre>list(object({<br/>    id              = optional(string)<br/>    allowed_headers = optional(list(string), [])<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    expose_headers  = optional(list(string), [])<br/>    max_age_seconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "allowed_headers": [<br/>      "*"<br/>    ],<br/>    "allowed_methods": [<br/>      "GET",<br/>      "HEAD"<br/>    ],<br/>    "allowed_origins": [<br/>      "*"<br/>    ],<br/>    "expose_headers": [<br/>      "ETag"<br/>    ],<br/>    "id": "allow-website-access",<br/>    "max_age_seconds": 3600<br/>  }<br/>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (dev, staging, prod) | `string` | `"prod"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply | `map(string)` | `{}` | no |
| <a name="input_website_error_document"></a> [website\_error\_document](#input\_website\_error\_document) | Error document for the website | `string` | `"error.html"` | no |
| <a name="input_website_index_document"></a> [website\_index\_document](#input\_website\_index\_document) | Index document for the website | `string` | `"index.html"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The name of the bucket |
| <a name="output_effective_public_access_block"></a> [effective\_public\_access\_block](#output\_effective\_public\_access\_block) | The effective public access block settings |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | The website domain |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | The website endpoint URL |
| <a name="output_website_url"></a> [website\_url](#output\_website\_url) | The full website URL |
<!-- END_TF_DOCS -->

