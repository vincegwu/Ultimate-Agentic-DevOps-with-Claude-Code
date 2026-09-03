---
name: project-staged-terraform-rollout
description: This project's terraform/ is being scaffolded incrementally — OIDC/IAM CI role and state-backend bootstrap resources are intentionally deferred, not a regression.
metadata:
  type: project
---

As of 2026-09-03, `terraform/` (backend.tf, main.tf, outputs.tf, providers.tf,
variables.tf) only contains the S3 + CloudFront static-site resources. There
is no `aws_iam_openid_connect_provider`, no GitHub Actions OIDC IAM role, no
`.github/workflows/` directory, and no S3 state bucket / DynamoDB lock table
resources in code — `backend.tf` is fully commented out and documents a
chicken-and-egg bootstrap order (state bucket + lock table must be created
out-of-band before the `backend "s3"` block can be uncommented).

**Why:** CLAUDE.md describes the *target* architecture (OIDC provider, IAM
role, S3 backend with DynamoDB locking) which this project builds toward via
dedicated skills (`/scaffold-cicd`, backend bootstrap step). The gaps are a
staged rollout, not something introduced by a bad edit.

**How to apply:** When auditing this repo, don't rate "missing OIDC trust
policy" / "missing state backend encryption" / "missing DynamoDB table" as
CRITICAL regressions if those resources simply don't exist yet in `terraform/`
— instead flag them as scope gaps relative to the intended architecture and
recommend running `/scaffold-cicd` (for OIDC/IAM) or the backend bootstrap
step (for state bucket + lock table) next. Always re-check via Glob whether
these files/resources have since been added — this memory reflects the state
at time of writing, not a permanent fact. See [[reference-security-checklist]]
if created later for the standing checklist this agent audits against.
