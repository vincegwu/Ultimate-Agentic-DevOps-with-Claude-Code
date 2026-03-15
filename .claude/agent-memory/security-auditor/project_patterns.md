---
name: project_patterns
description: Recurring security patterns and confirmed findings in this repo's Terraform (S3+CloudFront static site, berryapp project)
type: project
---

## Confirmed findings from 2026-03-15 audit

### CRITICAL — tfstate committed to git
`terraform/terraform.tfstate` is present in the repo. It contains AWS account ID (205930623242), CloudFront distribution ID, S3 ARNs, and the full rendered IAM policy with all real resource identifiers. This file should be in .gitignore and state should be migrated to the remote S3 backend defined in backend.tf.

### CRITICAL — Remote state backend not activated
`terraform/backend.tf` has the entire S3 backend block commented out. State is stored locally. No DynamoDB locking. Any concurrent apply risks state corruption.

### HIGH — TLS minimum protocol version is TLSv1 (deployed state)
The deployed CloudFront distribution uses `minimum_protocol_version = "TLSv1"` (confirmed in tfstate). The Terraform source does not set `minimum_protocol_version` when using `cloudfront_default_certificate`, so it defaults to the weakest value. TLSv1 and TLSv1.1 are deprecated. Should use `TLSv1.2_2021` with an ACM cert, or at minimum ensure the default cert path explicitly sets a modern minimum.

### HIGH — No CloudFront response headers policy (security headers missing)
`aws_cloudfront_distribution.site` has no `response_headers_policy_id` set on the default_cache_behavior. Confirmed in tfstate: `"response_headers_policy_id": ""`. Security headers (Content-Security-Policy, X-Frame-Options, Strict-Transport-Security, X-Content-Type-Options, Referrer-Policy) are absent from all responses.

### HIGH — CloudFront access logging disabled
`logging_config` is empty in both source and tfstate. No access logs means no audit trail for traffic anomalies or DDoS investigation.

### MEDIUM — S3 server-side encryption uses AWS-managed AES256, not KMS CMK
Confirmed in tfstate: `sse_algorithm: AES256`, `kms_master_key_id: ""`. S3 bucket uses SSE-S3 (AES256) rather than SSE-KMS with a customer-managed key, which limits key rotation control and audit trail.

### MEDIUM — S3 bucket versioning disabled
Confirmed in tfstate: `"versioning": [{"enabled": false}]`. No versioning means accidental overwrites or deletes of site files are unrecoverable without another deployment.

### MEDIUM — IPv6 disabled on CloudFront
Confirmed in tfstate: `"is_ipv6_enabled": false`. Modern best practice is to enable IPv6 on CloudFront distributions.

### MEDIUM — AWS account ID exposed in tfstate (committed to git)
Account ID `205930623242` is present in committed tfstate. Combined with the CRITICAL tfstate-in-git finding, this is an information-disclosure risk.

### LOW — No WAF (Web ACL) attached to CloudFront
`"web_acl_id": ""` in deployed state. For a public-facing distribution, AWS WAF provides protection against common exploits and rate limiting. Absence is a low risk for a static site but worth noting.

### LOW — CloudFront http_version is http2 only
Deployed distribution uses `http2`. AWS now supports `http2and3`; enabling HTTP/3 (QUIC) improves performance and security posture.

### CONFIRMED GOOD (do not re-flag)
- S3 public access block: all four flags true — PASS
- OAC (not legacy OAI) in use — PASS
- CloudFront viewer_protocol_policy = "redirect-to-https" — PASS
- S3 bucket policy scoped to specific CloudFront distribution ARN via SourceArn condition — PASS
- IAM actions minimal (s3:GetObject only) with no wildcards — PASS
- No hardcoded credentials in .tf source files — PASS
- GitHub OIDC used for CI/CD (no long-lived keys) — PASS (inferred from CLAUDE.md; no iam.tf present in current state — may not yet be deployed)
