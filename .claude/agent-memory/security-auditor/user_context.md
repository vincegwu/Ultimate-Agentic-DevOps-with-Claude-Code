---
name: user_context
description: User's infrastructure profile — static site on AWS S3+CloudFront, Terraform-managed, GitHub Actions CI/CD
type: user
---

- Project: "berryapp" static HTML/CSS portfolio site
- Infrastructure: AWS S3 (eu-north-1) + CloudFront, GitHub Actions OIDC auth, Terraform >= 1.5
- The user operates a single-environment production deployment (no staging separation observed in current state)
- Terraform remote state backend is defined but not yet activated (backend.tf is commented out)
- The user appears to be in an early/bootstrap phase — local tfstate is committed, remote backend not migrated yet
