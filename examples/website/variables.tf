# examples/website/variables.tf - Variables for Website Example

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "application_name" {
  description = "Name of the application using this bucket"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "website_index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}

variable "cors_rules" {
  description = "CORS rules for cross-origin access"
  type = list(object({
    id              = optional(string)
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = [
    {
      id              = "allow-website-access"
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
