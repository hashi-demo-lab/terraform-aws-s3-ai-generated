# versions.tf - Terraform and Provider Version Constraints
# This module requires Terraform >= 1.5.0 and AWS Provider >= 5.70.0

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
