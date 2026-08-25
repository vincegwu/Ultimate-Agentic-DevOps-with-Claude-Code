variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to tag and namespace project resources"
  type        = string
  default     = "portfolio-site"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Custom domain name for the site (leave empty to use the default CloudFront domain)"
  type        = string
  default     = ""
}
