# examples/basic/variables.tf - Variables for Basic Example

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
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
