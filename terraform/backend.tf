# ─── Remote State Backend ─────────────────────────────────────────────────────
#
# INSTRUCTIONS — two-phase bootstrap:
#
# Phase 1 (first run — no backend yet):
#   1. Keep this block commented out.
#   2. Run `terraform init && terraform apply` to create the S3 bucket and
#      DynamoDB table that will hold state.
#
# Phase 2 (migrate local state to S3):
#   1. Uncomment the backend block below.
#   2. Fill in the correct bucket name (from the output of Phase 1).
#   3. Run `terraform init -migrate-state` — Terraform will copy local state
#      to S3 and lock future operations with DynamoDB.
#
# ─────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket         = "berryapp-terraform-state"   # ← replace with your state bucket name
#     key            = "berryapp/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "berryapp-terraform-locks"
#     encrypt        = true
#   }
# }
