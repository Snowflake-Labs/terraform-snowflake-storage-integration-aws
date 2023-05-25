# Required
variable "snowflake_account" {
  type      = string
  sensitive = true
}

variable "prefix" {
  type        = string
  description = "this will be the prefix used to name the Resources"
}

# Optional
variable "snowflake_storage_integration_owner_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

variable "snowflake_integration_user_roles" {
  type        = list(string)
  default     = []
  description = "List of roles to which GEFF infra will GRANT USAGE ON INTEGRATION perms."
}

variable "aws_region" {
  description = "The AWS region in which the AWS infrastructure is created."
  type        = string
  default     = "us-west-2"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "data_bucket_arns" {
  type        = list(string)
  default     = []
  description = "List of Bucket ARNs for the s3_reader role to read from."
}

variable "arn_format" {
  type        = string
  description = "ARN format could be aws or aws-us-gov. Defaults to non-gov."
  default     = "aws"
}

variable "bucket_object_ownership_settings" {
  type        = string
  description = "The settings that will impact ACLs and ownership of objects within the bucket."
  default     = "BucketOwnerEnforced"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
