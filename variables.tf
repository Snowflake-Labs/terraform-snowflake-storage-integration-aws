# Required Variables
variable "snowflake_account" {
  type      = string
  sensitive = true
}

# Optional Variables
variable "aws_region" {
  description = "The AWS region in which the AWS infrastructure is created."
  default     = "us-west-2"
}

variable "prefix" {
  type        = string
  description = <<EOT
    This will be the prefix used to name the Resources.
    WARNING: Enter a short prefix in order to prevent name length related restrictions
  EOT
  default     = "example"
}

variable "aws_cloudwatch_metric_namespace" {
  type        = string
  description = "prefix for CloudWatch Metrics that GEFF writes"
  default     = "*"
}

variable "log_retention_days" {
  description = "Log retention period in days."
  default     = 0 # Forever
}

variable "env" {
  type        = string
  description = "Dev/Prod/Staging or any other custom environment name."
  default     = "dev"
}

variable "snowflake_integration_owner_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

variable "snowflake_integration_user_roles" {
  type        = list(string)
  default     = []
  description = "List of roles to which GEFF infra will GRANT USAGE ON INTEGRATION perms."
}

variable "deploy_lambda_in_vpc" {
  type        = bool
  description = "The security group VPC ID for the lambda function."
  default     = false
}

variable "lambda_security_group_ids" {
  type        = list(string)
  default     = []
  description = "The security group IDs for the lambda function."
}

variable "lambda_subnet_ids" {
  type        = list(string)
  default     = []
  description = "The subnet IDs for the lambda function."
}

variable "geff_image_version" {
  type        = string
  description = "Version of the GEFF docker image."
  default     = "latest"
}

variable "data_bucket_arns" {
  type        = list(string)
  default     = []
  description = "List of Bucket ARNs for the s3_reader role to read from."
}

variable "storage_only" {
  type        = bool
  default     = false
  description = "This flag allows to create the base infra for storage only pipelines."
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
}

locals {
  lambda_image_repo = "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/geff"
}

locals {
  lambda_image_repo_version = "${local.lambda_image_repo}:${var.geff_image_version}"
}

locals {
  inferred_api_gw_invoke_url = var.storage_only ? null : "https://${aws_api_gateway_rest_api.ef_to_lambda[0].id}.execute-api.${local.aws_region}.amazonaws.com/"
  geff_prefix                = "${var.prefix}_geff"
}

locals {
  lambda_function_name    = "${local.geff_prefix}_lambda"
  api_gw_caller_role_name = "${local.geff_prefix}_api_gateway_caller"
  api_gw_logger_role_name = "${local.geff_prefix}_api_gateway_logger"
  s3_reader_role_name     = "${local.geff_prefix}_s3_reader"
  s3_sns_policy_name      = "${local.geff_prefix}_s3_sns_topic_policy"
  s3_sns_topic_name       = "${local.geff_prefix}_bucket_sns"
}
