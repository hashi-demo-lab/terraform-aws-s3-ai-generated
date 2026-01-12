# TFLint configuration for Terraform AWS modules
# https://github.com/terraform-linters/tflint
#
# To install plugins, run: tflint --init
# Plugins may require GitHub API access. Set GITHUB_TOKEN if rate limited.

config {
  # Enable module inspection (v0.54.0+ syntax)
  call_module_type = "local"

  # Disable force mode (continue on errors for CI)
  force = false
}

# AWS plugin for AWS-specific rules
# Uncomment after running 'tflint --init'
# plugin "aws" {
#   enabled = true
#   version = "0.44.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
#   deep_check = false
# }

# Terraform plugin for general Terraform rules
# Uncomment after running 'tflint --init'
# plugin "terraform" {
#   enabled = true
#   version = "0.13.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-terraform"
# }

# Note: When plugins are disabled, only built-in rules apply.
# Enable plugins in CI/CD workflows where GITHUB_TOKEN is available.
