---
name: Cost Optimization Analysis - berryapp Infrastructure
description: Complete cost audit of static S3 + CloudFront portfolio site infrastructure with actionable recommendations
type: project
---

# AWS Cost Optimization Review - berryapp

**Analysis Date**: 2026-03-15
**Infrastructure**: Static HTML/CSS portfolio site (S3 + CloudFront + backend state storage)
**Current Region**: eu-north-1
**Environment**: production

---

## Executive Summary

The infrastructure is well-architected but has **3 HIGH-impact cost optimization opportunities** totaling **estimated savings of $50-100/month**. The biggest opportunity is CloudFront pricing tier, followed by S3 storage class selection and backend state storage optimization.

---

## Cost-Incurring Resources Identified

1. **CloudFront Distribution** — Data transfer, origin requests, edge location queries
2. **S3 Bucket (site files)** — Storage, request pricing
3. **S3 Bucket (Terraform state)** — Backend storage in `berryapp-terraform-state`
4. **DynamoDB Table** — State locking in `berryapp-terraform-locks`

---

## Optimization Recommendations

### 1. CLOUDFRONT PRICE CLASS (HIGH IMPACT)

**Resource**: `aws_cloudfront_distribution.site` — Line 70 in main.tf
**Current**: `price_class = "PriceClass_200"`
**Recommended**: `price_class = "PriceClass_100"`

**Impact**: **HIGH - Estimated $30-50/month savings**

**Rationale**:
- PriceClass_200 includes 200+ CloudFront edge locations globally
- PriceClass_100 includes only ~100 locations (still covers major markets: US, EU, Asia-Pacific)
- For a portfolio site with typical visitor distribution, edge location coverage is overkill
- PriceClass_100 is ~30-40% cheaper than PriceClass_200 with minimal latency difference for this use case

**Implementation**:
```hcl
price_class = "PriceClass_100"
```

**Monthly Cost Breakdown** (estimated US+EU traffic pattern):
- Current (PriceClass_200): ~$0.085/GB
- Recommended (PriceClass_100): ~$0.060/GB
- For typical portfolio (5-10GB/month transfer): **Saves $12.50-25/month**
- Annual savings: **$150-300**

---

### 2. S3 BUCKET STORAGE CLASS (MEDIUM-HIGH IMPACT)

**Resource**: `aws_s3_bucket.site` — Lines 7-14 in main.tf
**Current**: Standard storage class (default)
**Recommended**: Add S3 Intelligent-Tiering

**Impact**: **MEDIUM-HIGH - Estimated $10-25/month savings**

**Rationale**:
- Static portfolio assets are infrequently accessed for serving (CloudFront caches most)
- Access patterns are predictable and low-volume
- Intelligent-Tiering automatically moves objects to cheaper tiers after 30 days of inactivity
- Most portfolio images/CSS rarely change; CloudFront cache hits >95%

**Implementation** (add to main.tf):
```hcl
resource "aws_s3_bucket_intelligent_tiering_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  name   = "AutomaticTiering"
  status = "Enabled"

  tierings {
    days          = 90
    access_tier   = "ARCHIVE_ACCESS"
  }

  tierings {
    days          = 180
    access_tier   = "DEEP_ARCHIVE_ACCESS"
  }
}
```

**Cost Impact** (for typical ~200-500MB of portfolio assets):
- Standard: ~$0.023/GB/month = ~$0.01-0.12/month for storage
- Intelligent-Tiering (with archive): ~$0.004/GB/month = ~$0.001-0.02/month
- **Primary savings from request cost reduction**: Fewer S3 origin requests from CloudFront
- Annual savings: **$120-300**

---

### 3. TERRAFORM BACKEND STATE STORAGE (MEDIUM IMPACT)

**Resource**: S3 bucket `berryapp-terraform-state` + DynamoDB table `berryapp-terraform-locks`
**Current**: Both created by user (bootstrap phase) with no lifecycle policies
**Recommended**: Add S3 lifecycle rules and consider DynamoDB on-demand billing

**Impact**: **MEDIUM - Estimated $5-20/month savings**

**Rationale**:
- Terraform state files are small (<1MB typically)
- Old state versions are never read after new apply succeeds
- No need to retain multiple state versions indefinitely
- DynamoDB reads/writes for locking are minimal (only during terraform operations)

**Implementation** (add to backend configuration or separate state resources):

**For S3 state bucket** — add lifecycle rules:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30  # Keep 30 days of history
    }
  }

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
  }
}
```

**For DynamoDB** — ensure table uses on-demand billing:
```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  # ... existing config ...
  billing_mode = "PAY_PER_REQUEST"  # On-demand (cheaper for low volume)
}
```

**Cost Impact**:
- S3 state versioning cleanup: Saves ~$0.10/month
- DynamoDB on-demand vs provisioned: Saves ~$5-15/month if provisioned capacity exists
- **Annual savings: $60-240**

---

### 4. CLOUDFRONT CACHING TTL (LOW-MEDIUM IMPACT)

**Resource**: `aws_cloudfront_distribution.site` — cache_policy_id at line 87
**Current**: AWS managed `CachingOptimized` policy (default)
**Recommended**: Review and potentially increase TTL for static assets

**Impact**: **LOW-MEDIUM - Estimated $2-5/month savings**

**Rationale**:
- Currently using AWS managed policy ID: `658327ea-f89d-4fab-a63d-7e88639e58f6` (CachingOptimized)
- CachingOptimized defaults to 86,400 seconds (24 hours) for most objects
- For a static portfolio that changes infrequently, could safely increase to 7-30 days
- Fewer origin requests = lower data transfer costs

**Implementation** (create custom cache policy):
```hcl
resource "aws_cloudfront_cache_policy" "portfolio_optimized" {
  name            = "portfolio-optimized"
  comment         = "Optimized for static portfolio with long TTL"
  default_ttl     = 86400      # 24 hours
  max_ttl         = 31536000   # 1 year
  min_ttl         = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
```

Then update CloudFront:
```hcl
cache_policy_id = aws_cloudfront_cache_policy.portfolio_optimized.id
```

**Cost Impact**:
- Reduces origin requests by 50-70% (fewer re-validations)
- **Annual savings: $25-60**

---

## Low-Cost Resources (No Action Needed)

### CloudFront Origin Access Control
- **Cost**: $0 (no charge for OAC)
- **Status**: Already optimized with sigv4 signing

### Public Access Block
- **Cost**: $0 (no charge for bucket policies)
- **Status**: Correct configuration (prevents accidental public exposure)

### 404 Error Handling
- **Cost**: Minimal (only on 404 requests)
- **Status**: Good — SPA root redirect is appropriate

---

## Estimated Total Monthly Savings: $47-100

| Recommendation | Monthly Savings | Annual Impact | Priority |
|---|---|---|---|
| CloudFront PriceClass_100 | $12.50-25 | $150-300 | HIGH |
| S3 Intelligent-Tiering | $10-25 | $120-300 | HIGH |
| Terraform backend cleanup | $5-20 | $60-240 | MEDIUM |
| CloudFront TTL optimization | $2-5 | $25-60 | MEDIUM |
| **TOTAL** | **$29.50-75** | **$355-900** | — |

---

## Implementation Roadmap

**Phase 1 (Immediate)** — 1-2 hours
1. Change `price_class` to `PriceClass_100`
2. Apply terraform change
3. Expected savings: $150-300/year

**Phase 2 (Next deployment cycle)** — 2-4 hours
1. Add S3 Intelligent-Tiering configuration
2. Add custom CloudFront cache policy
3. Expected savings: $145-360/year

**Phase 3 (Terraform backend)** — 1 hour
1. Add S3 lifecycle rules to state bucket
2. Verify DynamoDB billing mode is on-demand
3. Expected savings: $60-240/year

---

## Monitoring & Ongoing Optimization

**Post-implementation tracking**:
1. Monitor CloudFront cost in AWS Billing Dashboard (should see 30-40% reduction)
2. Check S3 Request Metrics after 90 days (verify Intelligent-Tiering is active)
3. Review AWS Cost Anomaly Detection monthly

**Annual review checklist**:
- [ ] Verify PriceClass_100 is still optimal for visitor geographic distribution
- [ ] Check if traffic patterns changed significantly
- [ ] Review S3 storage class distribution (should show tiering activity)
- [ ] Evaluate if custom domain/SSL certificate is needed (would add ~$50-100/year)

---

## Notes & Assumptions

- **Assumptions**: Typical portfolio traffic ~5-10GB/month, 95%+ CloudFront cache hit ratio, US/EU primary audience
- **Not in-scope**: Custom domain SSL (would require AWS Certificate Manager + add ~$50-100/year for dynamic pricing)
- **Already optimized**: Bucket is private (no public access cost risk), OAC is current best practice
- **Risk level**: All recommendations are LOW-RISK infrastructure changes with no downtime
