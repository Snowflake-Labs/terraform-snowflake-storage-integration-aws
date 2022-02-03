# Required Variables
variable "prefix" {
  type        = string
  description = "This will be the prefix used to name the Resources."
}

# Optional Variables
variable "snowflake_storage_integration_owner_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

variable "env" {
  type        = string
  description = "Dev/Prod/Staging or any other custom environment name."
  default     = "dev"
}

variable "snowflake_integration_user_roles" {
  type        = list(string)
  default     = []
  description = "List of roles to which GEFF infra will GRANT USAGE ON INTEGRATION perms."
}

variable "data_bucket_arns" {
  type        = list(string)
  default     = []
  description = "List of Bucket ARNs for the s3_reader role to read from."
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
}

locals {
  s3_bucket_name        = "${replace(var.prefix, "_", "-")}-${var.env}-bucket" # Only hiphens + lower alphanumeric are allowed for bucket name
  s3_reader_role_name   = "${var.prefix}-s3-reader"
  s3_sns_policy_name    = "${var.prefix}-s3-sns-topic-policy"
  s3_bucket_policy_name = "${var.prefix}-rw-to-s3-bucket-policy"
  s3_sns_topic_name     = "${var.prefix}-bucket-sns"
}
