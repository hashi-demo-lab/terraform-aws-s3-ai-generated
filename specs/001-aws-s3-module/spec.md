# Feature Specification: Terraform AWS S3 Module

**Feature Branch**: `001-aws-s3-module`
**Created**: 2026-01-11
**Status**: Draft
**Input**: User description: "A comprehensive AWS S3 module supporting standard secure bucket (encryption, versioning, logging, public access blocks), static website hosting, and data lake storage with lifecycle policies. Compliance with CIS AWS Benchmark and SOC 2."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Standard Secure Bucket Deployment (Priority: P1)

As a cloud engineer, I need to deploy a secure S3 bucket with encryption, versioning, logging, and public access blocks enabled by default, so that my organization meets security compliance requirements without manual configuration.

**Why this priority**: Security is the foundation for all S3 use cases. A secure-by-default bucket is the most critical requirement as it prevents data breaches and ensures compliance. All other use cases build upon this secure foundation.

**Independent Test**: Can be fully tested by deploying a bucket with default settings and verifying all security controls are enabled. Delivers immediate value by providing a compliant storage solution.

**Acceptance Scenarios**:

1. **Given** default module configuration, **When** I apply the Terraform plan, **Then** the bucket is created with AES-256 or KMS encryption enabled
2. **Given** default module configuration, **When** I apply the Terraform plan, **Then** versioning is enabled on the bucket
3. **Given** a logging target bucket specified, **When** I apply the Terraform plan, **Then** server access logging is configured to write to the target bucket
4. **Given** default module configuration, **When** I apply the Terraform plan, **Then** all four public access block settings are enabled (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets)
5. **Given** KMS encryption is selected, **When** I apply the Terraform plan, **Then** a KMS key is created with appropriate key policy and rotation enabled

---

### User Story 2 - Static Website Hosting Configuration (Priority: P2)

As a web developer, I need to configure an S3 bucket for static website hosting with CORS support, so that I can serve web content directly from S3 with proper cross-origin resource sharing.

**Why this priority**: Static website hosting is a common use case that extends the secure bucket functionality. It requires specific configurations that relax some security defaults in a controlled manner.

**Independent Test**: Can be fully tested by deploying a website-enabled bucket and accessing the website endpoint. Delivers value by providing a static hosting solution.

**Acceptance Scenarios**:

1. **Given** website hosting is enabled, **When** I apply the Terraform plan, **Then** the bucket website configuration includes index and error document settings
2. **Given** website hosting is enabled with CORS rules, **When** I apply the Terraform plan, **Then** CORS configuration allows specified origins and methods
3. **Given** website hosting is enabled, **When** I apply the Terraform plan, **Then** a bucket policy is created allowing public read access for website content only
4. **Given** website hosting is enabled, **When** I access the website endpoint, **Then** the index document is served correctly

---

### User Story 3 - Data Lake Storage with Lifecycle Policies (Priority: P3)

As a data engineer, I need to configure an S3 bucket with lifecycle policies for cost optimization, so that data automatically transitions to cheaper storage classes and expires based on retention requirements.

**Why this priority**: Data lake storage requires lifecycle management for cost optimization, which builds on the secure bucket foundation. This is essential for large-scale data operations but is less urgent than basic security.

**Independent Test**: Can be fully tested by deploying a bucket with lifecycle rules and verifying transitions occur as configured. Delivers value by automating storage cost management.

**Acceptance Scenarios**:

1. **Given** lifecycle rules are configured, **When** I apply the Terraform plan, **Then** objects transition to Intelligent-Tiering after the specified number of days
2. **Given** lifecycle rules with Glacier transition, **When** I apply the Terraform plan, **Then** objects transition to Glacier storage class after the specified period
3. **Given** expiration rules are configured, **When** I apply the Terraform plan, **Then** objects are automatically deleted after the retention period
4. **Given** lifecycle rules for noncurrent versions, **When** I apply the Terraform plan, **Then** noncurrent versions expire after the specified days

---

### Edge Cases

- What happens when an invalid bucket name is provided? The module validates bucket naming conventions and returns a clear error message.
- How does the system handle conflicting configurations (e.g., website hosting with strict public access blocks)? The module detects conflicts and either auto-resolves with documented behavior or fails with a descriptive error.
- What happens when KMS key creation fails due to IAM permissions? The module provides clear error messages indicating required IAM permissions.
- How does the system handle cross-region replication requirements? Cross-region replication is out of scope for this module version but can be added via module outputs.

## Requirements *(mandatory)*

### Functional Requirements

#### Core Bucket Configuration
- **FR-001**: Module MUST create an S3 bucket with a unique, DNS-compliant name
- **FR-002**: Module MUST support optional bucket name prefix with random suffix generation for uniqueness
- **FR-003**: Module MUST apply resource tags including Name, Environment, and user-defined tags

#### Encryption Requirements
- **FR-004**: Module MUST enable server-side encryption by default using AES-256 (SSE-S3)
- **FR-005**: Module MUST support KMS encryption (SSE-KMS) as an alternative encryption option
- **FR-006**: When KMS encryption is selected, Module MUST create a dedicated KMS key with automatic key rotation enabled
- **FR-007**: Module MUST configure bucket default encryption to enforce encryption on all objects

#### Versioning Requirements
- **FR-008**: Module MUST enable versioning by default for data protection
- **FR-009**: Module MUST support optional MFA delete configuration for versioned buckets

#### Public Access Control
- **FR-010**: Module MUST enable all four S3 public access block settings by default (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets)
- **FR-011**: Module MUST allow selective disabling of public access blocks only when website hosting is explicitly enabled

#### Logging Requirements
- **FR-012**: Module MUST support server access logging configuration with a target bucket and prefix
- **FR-013**: Module MUST validate that the logging target bucket exists using a data source lookup and fail with a clear error message during `terraform plan` if the bucket does not exist or is inaccessible

#### Lifecycle Management
- **FR-014**: Module MUST support configurable lifecycle rules for storage class transitions
- **FR-015**: Module MUST support transitions to Intelligent-Tiering, Glacier Instant Retrieval, Glacier Flexible Retrieval, and Glacier Deep Archive
- **FR-016**: Module MUST support object expiration rules with configurable retention periods
- **FR-017**: Module MUST support noncurrent version expiration rules
- **FR-018**: Module MUST support lifecycle rules filtered by prefix and/or tags
- **FR-018a**: Module MUST validate that no more than 50 lifecycle rules are configured and reject configurations exceeding this limit with a clear error message

#### Website Hosting
- **FR-019**: Module MUST support optional static website hosting configuration
- **FR-020**: Module MUST configure index document and error document when website hosting is enabled
- **FR-021**: Module MUST create a bucket policy for public read access when website hosting is enabled

#### CORS Configuration
- **FR-022**: Module MUST support optional CORS configuration with customizable rules
- **FR-023**: Module MUST allow configuration of allowed origins, methods, headers, and max age
- **FR-023a**: Module MUST validate that no more than 10 CORS rules are configured and reject configurations exceeding this limit with a clear error message

#### Bucket Policy
- **FR-024**: Module MUST support custom bucket policy attachment
- **FR-025**: Module MUST enforce SSL/TLS for all bucket operations via bucket policy (deny non-HTTPS requests)

#### Input Validation
- **FR-026**: Module MUST implement input validation using Terraform variable validation blocks to surface errors during `terraform plan` before resource evaluation
- **FR-027**: Module MUST validate bucket naming conventions (lowercase, 3-63 characters, DNS-compliant)
- **FR-028**: Module MUST validate lifecycle rule count does not exceed 50 rules
- **FR-029**: Module MUST validate CORS rule count does not exceed 10 rules
- **FR-030**: Module MUST validate KMS key deletion window is between 7 and 30 days
- **FR-031**: Module MUST validate encryption_type is either "AES256" or "KMS"

### Non-Functional Requirements

- **NFR-001**: Module MUST be compatible with Terraform >= 1.5.0
- **NFR-002**: Module MUST use AWS Provider ~> 5.0
- **NFR-003**: Module MUST complete bucket creation within 5 minutes under normal conditions
- **NFR-004**: Module MUST be idempotent - repeated applies with same inputs produce no changes
- **NFR-005**: Module MUST support Terraform workspaces for environment isolation
- **NFR-006**: Module MUST provide meaningful output values for integration with other modules

### Security Requirements

- **SR-001**: Module MUST enforce encryption at rest for all objects by default
- **SR-002**: Module MUST block public access by default unless explicitly configured for website hosting
- **SR-003**: Module MUST enforce encryption in transit via bucket policy requiring HTTPS
- **SR-004**: Module MUST enable versioning to protect against accidental deletion
- **SR-005**: When KMS is used, Module MUST configure key policy to allow: (a) AWS account root for key administration, (b) IAM principals via IAM policies for key usage, and (c) a configurable admin role ARN (optional input variable) for key management delegation
- **SR-006**: Module MUST NOT allow bucket ACLs (enforce BucketOwnerEnforced object ownership)

### Key Entities

- **S3 Bucket**: The primary storage container with unique name, encryption, and versioning configuration
- **KMS Key**: Customer-managed encryption key with rotation policy and access controls (created when KMS encryption is selected)
- **Bucket Policy**: IAM policy document defining access permissions and security controls
- **Lifecycle Rule**: Configuration defining object transition and expiration behaviors
- **CORS Rule**: Cross-origin resource sharing configuration for web access

## Input Variables

| Variable                   | Type         | Required | Default              | Description                                                                 |
|----------------------------|--------------|----------|----------------------|-----------------------------------------------------------------------------|
| `bucket_name`              | string       | Yes      | -                    | Name of the S3 bucket (must be globally unique)                             |
| `bucket_prefix`            | string       | No       | null                 | Prefix for bucket name with random suffix                                   |
| `environment`              | string       | No       | "dev"                | Environment tag (dev, staging, prod)                                        |
| `tags`                     | map(string)  | No       | {}                   | Additional tags to apply to all resources                                   |
| `enable_versioning`        | bool         | No       | true                 | Enable versioning on the bucket                                             |
| `enable_mfa_delete`        | bool         | No       | false                | Enable MFA delete for versioned objects                                     |
| `encryption_type`          | string       | No       | "AES256"             | Encryption type: AES256 or KMS                                              |
| `kms_key_arn`              | string       | No       | null                 | ARN of existing KMS key (creates new if null and encryption_type is KMS)    |
| `kms_key_deletion_window`  | number       | No       | 30                   | Days before KMS key deletion (7-30)                                         |
| `enable_kms_key_rotation`  | bool         | No       | true                 | Enable automatic KMS key rotation                                           |
| `kms_admin_role_arn`       | string       | No       | null                 | ARN of IAM role granted KMS key administration permissions                  |
| `block_public_acls`        | bool         | No       | true                 | Block public ACLs                                                           |
| `block_public_policy`      | bool         | No       | true                 | Block public bucket policies                                                |
| `ignore_public_acls`       | bool         | No       | true                 | Ignore public ACLs                                                          |
| `restrict_public_buckets`  | bool         | No       | true                 | Restrict public bucket policies                                             |
| `enable_logging`           | bool         | No       | false                | Enable server access logging                                                |
| `logging_target_bucket`    | string       | No       | null                 | Target bucket for access logs                                               |
| `logging_target_prefix`    | string       | No       | "logs/"              | Prefix for log objects                                                      |
| `enable_website`           | bool         | No       | false                | Enable static website hosting                                               |
| `website_index_document`   | string       | No       | "index.html"         | Index document for website                                                  |
| `website_error_document`   | string       | No       | "error.html"         | Error document for website                                                  |
| `cors_rules`               | list(object) | No       | []                   | List of CORS rule configurations (max 10 rules)                             |
| `lifecycle_rules`          | list(object) | No       | []                   | List of lifecycle rule configurations (max 50 rules)                        |
| `bucket_policy`            | string       | No       | null                 | Custom bucket policy JSON                                                   |
| `force_destroy`            | bool         | No       | false                | Allow bucket deletion with objects                                          |
| `object_ownership`         | string       | No       | "BucketOwnerEnforced"| Object ownership setting                                                    |

## Output Variables

| Output                        | Type   | Description                                          |
|-------------------------------|--------|------------------------------------------------------|
| `bucket_id`                   | string | The name of the bucket                               |
| `bucket_arn`                  | string | The ARN of the bucket                                |
| `bucket_domain_name`          | string | The bucket domain name                               |
| `bucket_regional_domain_name` | string | The bucket region-specific domain name               |
| `bucket_hosted_zone_id`       | string | The Route 53 Hosted Zone ID for the bucket region    |
| `bucket_region`               | string | The AWS region the bucket resides in                 |
| `website_endpoint`            | string | The website endpoint (if website hosting enabled)    |
| `website_domain`              | string | The domain of the website endpoint                   |
| `kms_key_arn`                 | string | The ARN of the KMS key (if created)                  |
| `kms_key_id`                  | string | The ID of the KMS key (if created)                   |
| `logging_target_bucket`       | string | The logging target bucket name                       |
| `versioning_status`           | string | The versioning state of the bucket                   |

## Resource Dependencies

```
aws_kms_key (optional)
    |
    v
aws_s3_bucket
    |
    +---> aws_s3_bucket_versioning
    |
    +---> aws_s3_bucket_server_side_encryption_configuration
    |         |
    |         +---> depends on aws_kms_key (if KMS encryption)
    |
    +---> aws_s3_bucket_public_access_block
    |
    +---> aws_s3_bucket_logging
    |         |
    |         +---> depends on logging_target_bucket
    |
    +---> aws_s3_bucket_lifecycle_configuration
    |
    +---> aws_s3_bucket_website_configuration
    |
    +---> aws_s3_bucket_cors_configuration
    |
    +---> aws_s3_bucket_policy
              |
              +---> depends on aws_s3_bucket_public_access_block
```

## Compliance Mapping

### CIS AWS Foundations Benchmark v1.5.0

| CIS Control | Description                                                      | Implementation                                                                 |
|-------------|------------------------------------------------------------------|--------------------------------------------------------------------------------|
| 2.1.1       | Ensure S3 Bucket Policy is set to deny HTTP requests             | SR-003: Bucket policy enforces HTTPS via aws:SecureTransport condition         |
| 2.1.2       | Ensure MFA Delete is enabled on S3 buckets                       | FR-009: Optional MFA delete support via enable_mfa_delete variable             |
| 2.1.3       | Ensure all data in S3 bucket is discovered, classified, secured  | Out of scope - requires additional AWS services (Macie)                        |
| 2.1.4       | Ensure that S3 Buckets are configured with Block Public Access   | FR-010: All four public access block settings enabled by default               |
| 2.1.5       | Ensure that S3 Buckets are encrypted with KMS CMKs               | FR-005, FR-006: KMS encryption option with dedicated key creation              |

### SOC 2 Trust Service Criteria

| SOC 2 Control | Category             | Description                        | Implementation                                               |
|---------------|----------------------|------------------------------------|--------------------------------------------------------------|
| CC6.1         | Security             | Logical and physical access controls | FR-010, SR-002: Public access blocks, bucket policies        |
| CC6.6         | Security             | Encryption of data                 | FR-004, FR-005, SR-001, SR-003: Encryption at rest and in transit |
| CC6.7         | Security             | Protection against unauthorized access | FR-010, FR-024, SR-005: Access controls and policies         |
| CC7.2         | Security             | System monitoring                  | FR-012, FR-013: Server access logging                        |
| CC7.4         | Security             | Incident response                  | FR-008, SR-004: Versioning for data recovery                 |
| A1.2          | Availability         | Data backup and recovery           | FR-008, FR-014-FR-018: Versioning and lifecycle              |
| PI1.4         | Processing Integrity | Data completeness                  | FR-008: Versioning protects data integrity                   |

## Assumptions

1. **AWS Account Setup**: The AWS account has appropriate service quotas for S3 buckets and KMS keys
2. **IAM Permissions**: The executing principal has permissions to create S3 buckets, KMS keys, and bucket policies
3. **Logging Bucket**: When logging is enabled, the target bucket must already exist; the module validates existence via data source and fails during plan if not found
4. **Region Support**: All S3 storage classes used in lifecycle rules are available in the target region
5. **DNS Compliance**: Bucket names provided will follow S3 naming conventions (lowercase, no underscores, 3-63 characters)
6. **Object Lock**: Object Lock (WORM) is out of scope for this module version
7. **Replication**: Cross-region and same-region replication are out of scope for this module version
8. **Inventory**: S3 Inventory configuration is out of scope for this module version

## Clarifications

### Session 2026-01-11

- Q: Who should have access to the KMS key when SSE-KMS encryption is used? → A: Account root + any IAM principals via IAM policies + configurable admin role ARN (Option B)
- Q: What is the maximum number of lifecycle rules the module should accept? → A: 50 rules (typical data lake complexity with room for growth)
- Q: What is the maximum number of CORS rules the module should accept? → A: 10 rules (sufficient for most websites, easy to audit)
- Q: How should the module implement input validation? → A: Variable validation blocks (errors during plan, before resource evaluation)
- Q: How should the module handle invalid logging target bucket configurations? → A: Validate via data source and fail with clear error during plan

## Out of Scope

The following features are explicitly out of scope for this module version:

- S3 Object Lock (WORM compliance)
- Cross-region replication (CRR)
- Same-region replication (SRR)
- S3 Inventory configuration
- S3 Analytics configuration
- S3 Intelligent-Tiering Archive configurations
- S3 Access Points
- S3 Multi-Region Access Points
- S3 Event Notifications (SNS, SQS, Lambda)
- S3 Batch Operations

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Infrastructure engineers can deploy a compliant S3 bucket in under 5 minutes using default configuration
- **SC-002**: All deployed buckets pass CIS AWS Benchmark automated checks for S3 controls (2.1.1, 2.1.4, 2.1.5)
- **SC-003**: Module supports 100% of documented use cases (secure bucket, website hosting, data lake) without modification
- **SC-004**: Zero security findings in AWS Security Hub for deployed buckets using default configuration
- **SC-005**: Data lake configurations achieve measurable storage cost reduction through automated lifecycle transitions
- **SC-006**: Website-hosted buckets serve content with sub-second response times for cached requests
- **SC-007**: Module applies consistently across 10 consecutive Terraform applies with no drift detected
- **SC-008**: All input validation catches 100% of invalid configurations before AWS API calls

## Testing Requirements

### Unit Tests (Terraform Test Framework)

1. **Default Configuration Test**: Verify all security defaults are applied correctly
2. **KMS Encryption Test**: Verify KMS key creation and bucket encryption configuration
3. **Website Hosting Test**: Verify website configuration and CORS rules
4. **Lifecycle Rules Test**: Verify lifecycle policy configuration
5. **Input Validation Test**: Verify invalid inputs are rejected with clear messages

### Integration Tests

1. **End-to-End Deployment**: Deploy bucket and verify all resources created correctly
2. **Website Accessibility**: Deploy website bucket and verify HTTP access works
3. **Lifecycle Transition**: Deploy bucket with lifecycle rules and verify object transitions
4. **Cross-Module Integration**: Verify outputs can be consumed by dependent modules

### Compliance Tests

1. **CIS Benchmark Scan**: Run CIS AWS Benchmark checks against deployed bucket
2. **Security Hub Validation**: Verify no security findings for deployed resources
3. **Policy Validation**: Verify bucket policy enforces HTTPS requirement

### Acceptance Criteria for Testing

- All unit tests pass with 100% success rate
- All integration tests complete successfully in sandbox environment
- Compliance tests show zero critical or high findings
- Module documentation accurately reflects all features and limitations
