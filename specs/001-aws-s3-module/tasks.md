# Tasks: Terraform AWS S3 Module

**Input**: Design documents from `/workspace/specs/001-aws-s3-module/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md (required)
**Evaluations**: aws-security-review.md (7 findings), code-review-2026-01-12.md (8.4/10 score)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in descriptions

## Path Conventions (Terraform Module)

```text
terraform-aws-s3-module/
├── main.tf                          # Primary module resources
├── variables.tf                     # Input variable definitions
├── outputs.tf                       # Output value definitions
├── versions.tf                      # Terraform/provider version constraints
├── locals.tf                        # Local values and computations
├── data.tf                          # Data sources
├── examples/
│   ├── basic/
│   ├── complete/
│   └── website/
├── tests/
│   ├── unit-tests.tftest.hcl
│   ├── integration-tests.tftest.hcl
│   └── setup/
└── .github/workflows/
```

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize Terraform module structure and tooling

- [X] T001 Create project structure per plan.md section "Project Structure" at repository root
- [X] T002 [P] Create versions.tf with Terraform >= 1.5.0 and AWS Provider >= 5.70.0, < 6.0.0 constraints
- [X] T003 [P] Create .gitignore with standard Terraform patterns (*.tfstate, .terraform/, etc.)
- [X] T004 [P] Create .pre-commit-config.yaml with terraform_fmt, terraform_validate, terraform_docs, terraform_tflint, terraform_trivy hooks
- [X] T005 [P] Create .tflint.hcl with AWS-specific linting rules
- [X] T006 [P] Create trivy.yaml security scanning configuration
- [X] T007 [P] Create .terraform-docs.yml for README auto-generation

**Acceptance Criteria**:
- All configuration files created and validated
- Pre-commit hooks install without errors
- Directory structure matches plan.md

---

## Phase 2: Foundational (Core Infrastructure - BLOCKING)

**Purpose**: Core infrastructure required before user story implementation

**CRITICAL**: This phase addresses P1 security and code quality findings that MUST be resolved before production

### P1 Security Findings Resolution

- [X] T008 Create variables.tf with core variables per data-model.md section 1.1 (bucket_name, bucket_prefix, environment, tags, force_destroy)
- [X] T009 Add application_name variable (REQUIRED) per code-review P1 finding - violates AWS-TAG-001 without it
- [X] T010 Add bucket_name/bucket_prefix mutual exclusivity validation per code-review P1 finding
- [X] T011 Add encryption_type validation (AES256 or KMS) per data-model.md section 5.1
- [X] T012 Add kms_key_deletion_window validation (7-30 days) per data-model.md section 5.1
- [X] T013 Add environment validation (dev, staging, prod) per data-model.md section 5.1
- [X] T014 Add lifecycle_rules count validation (max 50) per data-model.md section 5.1
- [X] T015 Add cors_rules count validation (max 10) per data-model.md section 5.1

### P1 Security Findings - KMS Key Policy Constraints

- [X] T016 Create data.tf with aws_caller_identity data source for KMS key policy
- [X] T017 Create KMS key policy document with service-specific constraint (s3.amazonaws.com) per aws-security-review P1-002

### P1 Security Findings - Bucket Policy Encryption Enforcement

- [X] T018 Create bucket policy document with HTTPS enforcement (aws:SecureTransport condition) per plan.md
- [X] T019 Add server-side encryption enforcement policy statement per aws-security-review P1-001 - deny PutObject without encryption

### Core Module Structure

- [X] T020 Create locals.tf with computed values per data-model.md section 7:
  - bucket_name resolution (name vs prefix with random suffix)
  - create_kms_key conditional
  - kms_key_arn resolution
  - sse_algorithm determination
  - mandatory_tags (includes Application per AWS-TAG-001)
  - common_tags merge

- [X] T021 Create outputs.tf with bucket identifiers (bucket_id, bucket_arn) per data-model.md section 2.1
- [X] T022 [P] Add bucket endpoint outputs (domain_name, regional_domain_name, hosted_zone_id, region) per data-model.md section 2.2
- [X] T023 [P] Add KMS key outputs (kms_key_arn, kms_key_id) per data-model.md section 2.4
- [X] T024 [P] Add configuration status outputs (logging_target_bucket, versioning_status) per data-model.md section 2.5

### P2 Findings Resolution (Code Quality)

- [X] T025 Add MFA delete validation requiring versioning per aws-security-review P2-001
- [X] T026 Enhance logging target bucket validation with precondition per aws-security-review P2-002
- [X] T027 [P] Add lifecycle rule storage class validation (STANDARD_IA, INTELLIGENT_TIERING, GLACIER_IR, GLACIER, DEEP_ARCHIVE) per code-review
- [X] T028 [P] Add lifecycle rule transition days validation (>= 0) per code-review

**Checkpoint**: Foundation complete - all validations and security policies in place

---

## Phase 3: User Story 1 - Standard Secure Bucket Deployment (Priority: P1) MVP

**Goal**: Deploy a secure S3 bucket with encryption, versioning, logging, and public access blocks enabled by default

**Independent Test**: Deploy bucket with default settings and verify all security controls are enabled

**Acceptance Criteria**:
1. Bucket created with AES-256 encryption by default
2. Versioning enabled by default
3. All four public access blocks enabled
4. HTTPS enforced via bucket policy
5. Encryption enforced via bucket policy (P1-001 fix)
6. terraform validate passes
7. Unit tests pass

### Unit Tests for User Story 1

- [X] T029 [P] [US1] Create tests/unit-tests.tftest.hcl with terraform validate test
- [X] T030 [P] [US1] Add unit test: invalid_bucket_name_rejected (expect_failures)
- [X] T031 [P] [US1] Add unit test: valid_bucket_name_accepted
- [X] T032 [P] [US1] Add unit test: invalid_encryption_type_rejected (expect_failures)
- [X] T033 [P] [US1] Add unit test: invalid_kms_deletion_window_rejected (expect_failures)
- [X] T034 [P] [US1] Add unit test: invalid_environment_rejected (expect_failures)
- [X] T035 [P] [US1] Add unit test: default_values_applied (versioning=true, encryption=AES256)
- [X] T036 [P] [US1] Add unit test: bucket_policy_includes_https_enforcement
- [X] T037 [P] [US1] Add unit test: bucket_policy_includes_encryption_enforcement (P1-001 validation)
- [X] T038 [P] [US1] Add unit test: kms_key_policy_uses_least_privilege (P1-002 validation)

### Implementation for User Story 1

- [X] T039 [US1] Create random_id resource for bucket_prefix suffix generation in main.tf
- [X] T040 [US1] Create aws_kms_key resource with conditional creation (encryption_type == "KMS" && kms_key_arn == null) in main.tf
- [X] T041 [US1] Add KMS key policy with:
  - Account root full access (AllowRootAccountFullAccess)
  - S3 service principal access (AllowS3ToUseKey) per P1-002 fix
  - IAM read-only access with CallerAccount condition
  - Optional admin role permissions
- [X] T042 [US1] Create aws_s3_bucket resource with bucket name, force_destroy, and tags in main.tf
- [X] T043 [US1] Create aws_s3_bucket_ownership_controls resource with BucketOwnerEnforced in main.tf
- [X] T044 [US1] Create aws_s3_bucket_versioning resource with Enabled status (default) in main.tf
- [X] T045 [US1] Create aws_s3_bucket_server_side_encryption_configuration resource with AES256/KMS in main.tf
- [X] T046 [US1] Create aws_s3_bucket_public_access_block resource with all four blocks enabled in main.tf
- [X] T047 [US1] Create aws_s3_bucket_policy resource with combined policy (HTTPS + encryption enforcement) in main.tf

### Integration Test for User Story 1

- [X] T048 [US1] Create tests/integration-tests.tftest.hcl with basic_bucket_creation test (command = apply)
- [X] T049 [US1] Add integration test assertions:
  - bucket_id is set
  - versioning_status == "Enabled"
  - All public access blocks are true
  - encryption_type in bucket configuration

### Example for User Story 1

- [X] T050 [P] [US1] Create examples/basic/main.tf with minimal secure bucket configuration
- [X] T051 [P] [US1] Create examples/basic/variables.tf with required inputs
- [X] T052 [P] [US1] Create examples/basic/outputs.tf with key outputs
- [X] T053 [P] [US1] Create examples/basic/README.md with usage instructions

**Checkpoint**: User Story 1 complete - secure bucket deployable with default settings

---

## Phase 4: User Story 2 - Static Website Hosting Configuration (Priority: P2)

**Goal**: Configure an S3 bucket for static website hosting with CORS support

**Independent Test**: Deploy a website-enabled bucket and access the website endpoint

**Acceptance Criteria**:
1. Website configuration includes index and error documents
2. CORS configuration allows specified origins and methods
3. Bucket policy allows public read access for website content
4. Public access blocks automatically adjusted for website mode (P2-003 documented)
5. Website endpoint accessible

### Unit Tests for User Story 2

- [X] T054 [P] [US2] Add unit test: website_public_access_adjusted (block_public_policy=false when enable_website=true)
- [X] T055 [P] [US2] Add unit test: cors_rules_max_exceeded (expect_failures for > 10 rules)
- [X] T056 [P] [US2] Add unit test: bucket_policy_includes_website_public_read_when_enabled

### Variables for User Story 2

- [X] T057 [P] [US2] Add website hosting variables to variables.tf:
  - enable_website (bool, default=false)
  - website_index_document (string, default="index.html")
  - website_error_document (string, default="error.html")
- [X] T058 [P] [US2] Add CORS configuration variable to variables.tf per data-model.md section 1.7 (cors_rules list)
- [X] T059 [US2] Add website_block_public_policy and website_restrict_public_buckets locals for automatic adjustment

### Implementation for User Story 2

- [X] T060 [US2] Update aws_s3_bucket_public_access_block to use computed values when website enabled
- [X] T061 [US2] Create aws_s3_bucket_website_configuration resource (conditional: enable_website) in main.tf
- [X] T062 [US2] Create website public read policy document (AllowPublicRead for s3:GetObject) in data.tf
- [X] T063 [US2] Update aws_s3_bucket_policy to merge website public read policy when enabled
- [X] T064 [US2] Create aws_s3_bucket_cors_configuration resource (conditional: length(cors_rules) > 0) in main.tf

### Outputs for User Story 2

- [X] T065 [P] [US2] Add website outputs to outputs.tf (website_endpoint, website_domain)
- [X] T066 [P] [US2] Add effective_public_access_block output per aws-security-review P2-003

### Integration Test for User Story 2

- [X] T067 [US2] Add integration test: website_bucket_creation with website endpoint assertions

### Example for User Story 2

- [X] T068 [P] [US2] Create examples/website/main.tf with static website configuration
- [X] T069 [P] [US2] Create examples/website/variables.tf with website-specific inputs
- [X] T070 [P] [US2] Create examples/website/outputs.tf with website endpoint outputs
- [X] T071 [P] [US2] Create examples/website/README.md with CORS and website configuration examples

**Checkpoint**: User Story 2 complete - website hosting with CORS fully functional

---

## Phase 5: User Story 3 - Data Lake Storage with Lifecycle Policies (Priority: P3)

**Goal**: Configure an S3 bucket with lifecycle policies for cost optimization

**Independent Test**: Deploy bucket with lifecycle rules and verify transitions are configured

**Acceptance Criteria**:
1. Objects transition to Intelligent-Tiering after specified days
2. Objects transition to Glacier storage class after specified period
3. Objects automatically deleted after retention period
4. Noncurrent versions expire after specified days
5. Lifecycle rules configurable up to 50 rules

### Unit Tests for User Story 3

- [X] T072 [P] [US3] Add unit test: lifecycle_rules_max_exceeded (expect_failures for > 50 rules)
- [X] T073 [P] [US3] Add unit test: lifecycle_storage_class_validation (expect_failures for invalid storage class)
- [X] T074 [P] [US3] Add unit test: lifecycle_rules_applied (verify rules in plan output)

### Variables for User Story 3

- [X] T075 [P] [US3] Add lifecycle configuration variable to variables.tf per data-model.md section 1.8 (lifecycle_rules list with full object type)

### Implementation for User Story 3

- [X] T076 [US3] Create aws_s3_bucket_lifecycle_configuration resource (conditional: length(lifecycle_rules) > 0) in main.tf
- [X] T077 [US3] Implement lifecycle rule dynamic blocks:
  - transitions (days, storage_class)
  - noncurrent_version_transitions
  - expiration
  - noncurrent_version_expiration
  - abort_incomplete_multipart_upload
- [X] T078 [US3] Implement filter block with prefix and tags support

### Integration Test for User Story 3

- [X] T079 [US3] Add integration test: lifecycle_rules_applied with lifecycle configuration assertions

### Example for User Story 3

- [X] T080 [P] [US3] Create examples/complete/main.tf with full-featured configuration (encryption, logging, lifecycle, all features)
- [X] T081 [P] [US3] Create examples/complete/variables.tf with all available inputs
- [X] T082 [P] [US3] Create examples/complete/outputs.tf with all outputs
- [X] T083 [P] [US3] Create examples/complete/README.md with comprehensive usage examples

**Checkpoint**: User Story 3 complete - lifecycle policies fully configurable

---

## Phase 6: Logging Configuration (Extended Features)

**Goal**: Implement server access logging with target bucket validation

**Acceptance Criteria**:
1. Logging configurable with target bucket and prefix
2. Target bucket existence validated during plan (P2-002)
3. Logging compatible with BucketOwnerEnforced object ownership

### Implementation for Logging

- [X] T084 Add logging variables to variables.tf (enable_logging, logging_target_bucket, logging_target_prefix)
- [X] T085 Create data.aws_s3_bucket.logging_target data source with conditional lookup in data.tf
- [X] T086 Create aws_s3_bucket_logging resource with precondition validation in main.tf
- [ ] T087 Add integration test: logging_configuration with logging target assertions

**Checkpoint**: Logging configuration complete with validation

---

## Phase 7: Custom Bucket Policy Support

**Goal**: Allow custom bucket policies merged with security defaults

**Acceptance Criteria**:
1. Custom policy merged with HTTPS enforcement
2. Custom policy merged with website policy when enabled
3. Policy composition follows documented order

### Implementation for Custom Policy

- [X] T088 Add bucket_policy variable (string, JSON) to variables.tf
- [X] T089 Update combined policy document to merge custom policy per plan.md section "Bucket Policy Composition Strategy"
- [ ] T090 Add unit test: bucket_policy_merges_custom_policy

**Checkpoint**: Custom bucket policy support complete

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, CI/CD, and final quality improvements

### Documentation

- [ ] T091 [P] Generate README.md using terraform-docs with module description, inputs, outputs, examples
- [ ] T092 [P] Create CHANGELOG.md with v1.0.0 entry documenting all features
- [ ] T093 [P] Create LICENSE file (MPL-2.0 per plan.md)
- [ ] T094 [P] Create examples/README.md with overview of all examples

### CI/CD Workflows

- [ ] T095 [P] Create .github/workflows/module_validate.yml for PR validation (fmt, validate, tflint, trivy)
- [ ] T096 [P] Create .github/workflows/module_publish.yml for registry publication
- [ ] T097 [P] Create .github/workflows/breaking_changes.yml for breaking change detection

### Test Fixtures

- [X] T098 Create tests/setup/main.tf with logging target bucket fixture per code-review recommendation
- [X] T099 Create tests/setup/outputs.tf with fixture outputs
- [X] T100 Create tests/setup/versions.tf with provider constraints

### Final Validation

- [X] T101 Run terraform fmt -check -recursive on all .tf files
- [X] T102 Run terraform validate on module and all examples
- [ ] T103 Run tflint --config .tflint.hcl on module
- [ ] T104 Run trivy config . for security scanning
- [ ] T105 Run terraform test for full test suite
- [ ] T106 Verify README.md is complete and accurate
- [ ] T107 Run quickstart.md validation scenarios

### P3 Findings Resolution (Optional Enhancements)

- [ ] T108 [P] Add CloudTrail data events documentation to README.md per aws-security-review P3-001
- [ ] T109 [P] Enhance bucket_prefix documentation with random suffix details per aws-security-review P3-002

**Checkpoint**: Module complete and ready for v1.0.0 release

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
     │
     ▼
Phase 2 (Foundational) ─── BLOCKS ALL USER STORIES
     │
     ├─────────────────────────────────────────────────────────┐
     │                                                         │
     ▼                                                         ▼
Phase 3 (US1: Secure Bucket)                    Phases 4, 5, 6, 7 can start in parallel
     │                                          after Phase 2 (if team capacity allows)
     ▼
Phase 4 (US2: Website Hosting)
     │
     ▼
Phase 5 (US3: Lifecycle Policies)
     │
     ▼
Phase 6 (Logging)
     │
     ▼
Phase 7 (Custom Policy)
     │
     ▼
Phase 8 (Polish)
```

### Critical Path (Sequential)

1. **Setup (Phase 1)**: T001-T007 - No dependencies
2. **Foundational (Phase 2)**: T008-T028 - BLOCKS all user stories
   - P1 security findings MUST be resolved here
   - P2 code quality findings addressed here
3. **User Story 1 (Phase 3)**: T029-T053 - MVP delivery
4. **User Story 2 (Phase 4)**: T054-T071 - Website hosting
5. **User Story 3 (Phase 5)**: T072-T083 - Lifecycle policies
6. **Logging (Phase 6)**: T084-T087
7. **Custom Policy (Phase 7)**: T088-T090
8. **Polish (Phase 8)**: T091-T109 - Documentation and validation

### Security Finding Dependencies

| Finding | Task(s) | Phase | Status |
|---------|---------|-------|--------|
| P1-001: Encryption enforcement policy | T019, T037 | 2, 3 | Must fix before production |
| P1-002: KMS key service constraint | T017, T041, T038 | 2, 3 | Must fix before production |
| P2-001: MFA delete validation | T025 | 2 | Should fix before production |
| P2-002: Logging target validation | T026, T086 | 2, 6 | Should fix before production |
| P2-003: Website public access docs | T059, T066 | 4 | Should fix before v1.0.0 |
| P3-001: CloudTrail documentation | T108 | 8 | Optional enhancement |
| P3-002: Bucket prefix documentation | T109 | 8 | Optional enhancement |

### Parallel Opportunities Within Phases

**Phase 1 (Setup)**:
```bash
# All setup tasks can run in parallel
T002, T003, T004, T005, T006, T007
```

**Phase 2 (Foundational)**:
```bash
# Variable validations can run in parallel
T011, T012, T013, T014, T015, T027, T028

# Outputs can run in parallel
T022, T023, T024
```

**Phase 3 (User Story 1)**:
```bash
# Unit tests can run in parallel
T029, T030, T031, T032, T033, T034, T035, T036, T037, T038

# Examples can run in parallel
T050, T051, T052, T053
```

**Phase 4 (User Story 2)**:
```bash
# Unit tests can run in parallel
T054, T055, T056

# Variables can run in parallel
T057, T058

# Outputs can run in parallel
T065, T066

# Examples can run in parallel
T068, T069, T070, T071
```

**Phase 5 (User Story 3)**:
```bash
# Unit tests can run in parallel
T072, T073, T074

# Examples can run in parallel
T080, T081, T082, T083
```

**Phase 8 (Polish)**:
```bash
# Documentation can run in parallel
T091, T092, T093, T094

# Workflows can run in parallel
T095, T096, T097

# P3 findings can run in parallel
T108, T109
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) - Recommended

1. Complete Phase 1: Setup (7 tasks)
2. Complete Phase 2: Foundational with P1/P2 fixes (21 tasks)
3. Complete Phase 3: User Story 1 - Secure Bucket (25 tasks)
4. **STOP and VALIDATE**:
   - All unit tests pass (< 10 seconds)
   - Integration test passes
   - `terraform validate` passes
   - Security scanning passes
5. Deploy/demo secure bucket capability

**MVP Total**: 53 tasks for production-ready secure bucket

### Full Implementation

1. MVP (Phases 1-3): 53 tasks
2. Add Website Hosting (Phase 4): 18 tasks
3. Add Lifecycle Policies (Phase 5): 12 tasks
4. Add Logging (Phase 6): 4 tasks
5. Add Custom Policy (Phase 7): 3 tasks
6. Polish & Documentation (Phase 8): 19 tasks

**Total**: 109 tasks for complete module

### Estimated Effort

| Phase | Tasks | Estimated Hours |
|-------|-------|-----------------|
| Setup | 7 | 1 hour |
| Foundational | 21 | 3 hours |
| User Story 1 | 25 | 4 hours |
| User Story 2 | 18 | 3 hours |
| User Story 3 | 12 | 2 hours |
| Logging | 4 | 1 hour |
| Custom Policy | 3 | 0.5 hours |
| Polish | 19 | 3 hours |
| **Total** | **109** | **17.5 hours** |

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 109 |
| **P1 Security Tasks** | 8 (T017-T019, T037-T038, T041) |
| **P2 Quality Tasks** | 6 (T025-T028, T059, T066) |
| **P3 Enhancement Tasks** | 2 (T108-T109) |
| **User Story 1 Tasks** | 25 |
| **User Story 2 Tasks** | 18 |
| **User Story 3 Tasks** | 12 |
| **Parallel Opportunities** | 45 tasks marked [P] |
| **MVP Scope** | Phases 1-3 (53 tasks) |

### Independent Test Criteria

| User Story | Independent Test |
|------------|------------------|
| US1: Secure Bucket | Deploy with defaults, verify encryption, versioning, public access blocks, HTTPS policy |
| US2: Website Hosting | Deploy with enable_website=true, access website endpoint, verify CORS |
| US3: Lifecycle Policies | Deploy with lifecycle_rules, verify rules configured in AWS console |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story (US1, US2, US3)
- P1 security findings MUST be resolved in Phase 2 before user story implementation
- Each user story is independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
