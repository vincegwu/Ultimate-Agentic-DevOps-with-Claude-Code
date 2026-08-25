# Terraform state backend configuration
#
# Bootstrap order:
#   1. Leave this block commented out and run `terraform init` to use local state.
#   2. `terraform apply` to create the S3 state bucket and DynamoDB lock table
#      (define these resources separately, e.g. in a one-time bootstrap config,
#      since a backend cannot reference resources from the same configuration
#      it stores state for).
#   3. Uncomment the backend block below, filling in the bucket/table names.
#   4. Run `terraform init -migrate-state` to move local state into S3.
#
# terraform {
#   backend "s3" {
#     bucket         = "portfolio-site-terraform-state"
#     key            = "portfolio-site/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "portfolio-site-terraform-locks"
#     encrypt        = true
#   }
# }
