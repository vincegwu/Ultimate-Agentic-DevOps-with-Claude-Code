---
name: terraform-cost-review-sep2026
description: Cost optimization audit of portfolio site infrastructure (S3+CloudFront static site)
metadata:
  type: project
  reviewed_date: 2026-09-03
  scope: terraform/ directory (providers, main, variables, outputs, backend)
---

# Terraform Cost Review — Portfolio Site Infrastructure

## Audit Summary

Static portfolio site infrastructure (S3+CloudFront) is well-optimized overall. Current monthly cost estimate: **$5–15/mo** (S3 ~$1, CloudFront ~$5–10 at low traffic).

**One immediate action identified**: CloudFront Price Class downgrade (PriceClass_200 → PriceClass_100)

## Findings

### 1. CloudFront Price Class — HIGH PRIORITY
- **Current**: PriceClass_200 (line main.tf:75)
- **Issue**: Includes expensive regions (Asia, Middle East) unnecessary for regional portfolio
- **Fix**: Change to PriceClass_100
- **Impact**: $0.50–1.50/mo now; up to $10–20/mo if traffic scales
- **Risk**: None; safe change

### 2. DynamoDB Billing Mode (Future) — MEDIUM PRIORITY
- **Current**: backend.tf:12–20 commented out; no billing mode specified
- **Issue**: When enabled, defaults to provisioned capacity (unnecessary cost)
- **Fix**: Add `billing_mode = "PAY_PER_REQUEST"` when bootstrapping DynamoDB
- **Impact**: $0.25–1.00/mo when enabled; negligible but avoids waste
- **Risk**: None; standard practice

### 3. S3 Versioning Lifecycle (Preventive) — MEDIUM PRIORITY
- **Current**: main.tf:12–16; no versioning or lifecycle rules
- **Status**: Correct now (versioning disabled)
- **Future**: If versioning added, immediately add 30-day noncurrent expiration
- **Impact**: Prevents $0.10–0.50/mo cost creep per GB of versions
- **Risk**: None; only needed if versioning enabled

### 4. S3 Storage Class — OK
- Current STANDARD class is appropriate (high access frequency via CloudFront)
- Do not switch to Intelligent-Tiering (unnecessary complexity)

### 5. CloudFront Logging — OK
- No logging configured (correct; logging costs $0.01/request for minimal value)

## No Unnecessary Resources Found
- All resources are minimal and purposeful
- No NAT gateways, unused EIPs, overprovisioned resources, or compute overhead
- Security is well-implemented (OAC, bucket policies, public access blocking)

## Recommendations Prioritized

1. **NOW**: Downgrade CloudFront Price Class to PriceClass_100 (main.tf:75)
2. **WHEN DynamoDB IS ENABLED**: Specify `billing_mode = "PAY_PER_REQUEST"` (currently in bootstrap notes)
3. **WHEN S3 VERSIONING IS ENABLED**: Add lifecycle rule for old versions
4. **NOT NEEDED**: Any other changes; infrastructure is right-sized
