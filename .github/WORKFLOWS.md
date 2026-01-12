# CI/CD Workflows Documentation

This document describes the GitHub Actions workflows available for Terraform module development.

## Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `module_validate.yml` | PR to main | Validate code quality |
| `module_release_tag.yml` | New tag (v*) | Tag-based PMR release |
| `module_release_branch.yml` | PR merge to main | Branch-based PMR release |
| `module_integration_tests.yml` | Manual/Scheduled | Run integration tests |
| `breaking_changes.yml` | PR changes to variables/outputs | Detect breaking changes |

## Tag-Based vs Branch-Based PMR

### Tag-Based PMR Sources

```
Repository → Tag (v1.0.0) → PMR Auto-Detects → Published
```

**Characteristics:**
- ✅ Automatic publishing when tags are created
- ✅ Simple workflow - just create a release
- ❌ PMR cannot run tests (tests must run before tagging)
- ❌ Less control over publication timing

**Workflow:** `module_release_tag.yml`

1. Create a tag/release in GitHub (e.g., `v1.0.0`)
2. Workflow runs integration tests
3. Creates GitHub Release with changelog
4. PMR automatically detects and publishes the tag

### Branch-Based PMR Sources

```
Repository → Merge to main → Workflow calculates version → API publishes with commit SHA
```

**Characteristics:**
- ✅ PMR can run tests after publication
- ✅ Full control over version calculation
- ✅ Automatic version bumping from PR labels
- ❌ Requires manual API call to publish
- ❌ Must specify commit SHA when publishing

**Workflow:** `module_release_branch.yml`

1. Create PR with `semver:patch`, `semver:minor`, or `semver:major` label
2. Merge PR to main
3. Workflow calculates next version from PMR or git tags
4. Publishes to PMR via API with commit SHA
5. Creates git tag and GitHub Release
6. PMR runs configured tests

## Workflow Details

### 1. Module Validate (`module_validate.yml`)

**Triggers:** Pull requests modifying `.tf`, `.tfvars`, `.tftest.hcl` files

**Steps:**
1. Check for required semver label
2. Terraform format check
3. Terraform init and validate
4. Validate all examples
5. TFLint analysis
6. Trivy security scanning
7. Run unit tests
8. Auto-update README via terraform-docs
9. Post PR comment with results

**Required Labels:**
- `semver:patch` - Bug fixes (1.0.0 → 1.0.1)
- `semver:minor` - New features (1.0.0 → 1.1.0)
- `semver:major` - Breaking changes (1.0.0 → 2.0.0)

### 2. Tag-Based Release (`module_release_tag.yml`)

**Triggers:** Push of tags matching `v[0-9]+.[0-9]+.[0-9]+*`

**Steps:**
1. Validate semantic version format
2. Run integration tests (optional)
3. Generate changelog from commits
4. Create GitHub Release
5. PMR auto-detects new tag

**Inputs:**
- `skip_tests` - Skip integration tests
- `dry_run` - Calculate version without releasing

### 3. Branch-Based Release (`module_release_branch.yml`)

**Triggers:** Pull request closed (merged) to main/master

**Steps:**
1. Check for semver label
2. Query PMR for current version
3. Calculate next version
4. Publish to PMR via API with commit SHA
5. Create git tag
6. Create GitHub Release

**Required Variables:**
- `TFE_ORG` - Terraform Cloud organization
- `TFE_MODULE` - Module name
- `TFE_PROVIDER` - Provider (aws, azurerm, google)
- `TFE_HOSTNAME` - (Optional) TFE hostname, defaults to app.terraform.io

**Required Secrets:**
- `TFE_TOKEN` - Terraform Cloud API token

### 4. Integration Tests (`module_integration_tests.yml`)

**Triggers:** Manual, scheduled (weekly), or called by other workflows

**Steps:**
1. Setup test fixtures
2. Configure AWS credentials
3. Run integration tests
4. Cleanup test fixtures

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Inputs:**
- `test_filter` - Filter specific test files
- `destroy_on_failure` - Whether to cleanup on failure

### 5. Breaking Changes (`breaking_changes.yml`)

**Triggers:** PR changes to `variables.tf`, `outputs.tf`, `versions.tf`

**Detects:**
- Removed or renamed variables
- Changed variable types
- Removed default values (making variables required)
- Removed or renamed outputs
- New required variables without defaults

**Output:** PR comment with analysis and semver recommendation

## Repository Setup

### Required Labels

Create these labels in your repository:

```bash
gh label create "semver:patch" --color "0E8A16" --description "Bug fix release"
gh label create "semver:minor" --color "1D76DB" --description "Feature release"
gh label create "semver:major" --color "B60205" --description "Breaking change release"
```

### Required Secrets

Configure these in repository settings:

| Secret | Description | Required For |
|--------|-------------|--------------|
| `TFE_TOKEN` | Terraform Cloud API token | Branch-based release |
| `AWS_ACCESS_KEY_ID` | AWS credentials | Integration tests |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials | Integration tests |

### Required Variables

Configure these in repository settings:

| Variable | Description | Example |
|----------|-------------|---------|
| `TFE_ORG` | TFC organization name | `my-org` |
| `TFE_MODULE` | Module name | `s3-bucket` |
| `TFE_PROVIDER` | Provider name | `aws` |
| `TFE_HOSTNAME` | TFE hostname (optional) | `app.terraform.io` |
| `AWS_REGION` | AWS region (optional) | `us-east-1` |

## Choosing Your Approach

### Use Tag-Based When:
- You want simple, manual control over releases
- You're comfortable running tests before tagging
- You want PMR to auto-detect releases
- You're using public registry or simple PMR setup

### Use Branch-Based When:
- You want automatic version calculation
- You want PMR to run tests after publication
- You need audit trail of commit SHAs
- You have complex CI/CD requirements
- You want to enforce semver labels on PRs

## Pre-commit Integration

The `.pre-commit-config.yaml` provides local enforcement:

```bash
# Install hooks
pre-commit install

# Run all hooks
pre-commit run --all-files

# Update hooks to latest versions
pre-commit autoupdate
```

Hooks run:
- On commit: format, validate, lint, security scan, docs
- On push: unit tests, semver reminder
