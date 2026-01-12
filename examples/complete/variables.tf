# examples/complete/variables.tf - Variables for Complete Example

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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

variable "lifecycle_rules" {
  description = "Lifecycle rules for the data lake bucket"
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
  default = [
    {
      id      = "raw-data-tiering"
      enabled = true
      prefix  = "raw/"
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER_IR" },
        { days = 180, storage_class = "GLACIER" },
        { days = 365, storage_class = "DEEP_ARCHIVE" }
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "processed-data-tiering"
      enabled = true
      prefix  = "processed/"
      transitions = [
        { days = 60, storage_class = "INTELLIGENT_TIERING" }
      ]
      expiration = {
        days = 730
      }
    },
    {
      id      = "temp-cleanup"
      enabled = true
      prefix  = "temp/"
      expiration = {
        days = 7
      }
    }
  ]
}

variable "cors_rules" {
  description = "CORS rules for the data lake bucket"
  type = list(object({
    id              = optional(string)
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default = {
    Project    = "DataPlatform"
    CostCenter = "Analytics"
  }
}
