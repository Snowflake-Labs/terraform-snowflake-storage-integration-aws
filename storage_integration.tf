locals {
  pipeline_bucket_ids = [
    for bucket_arn in var.data_bucket_arns : element(split(":::", bucket_arn), 1)
  ]
  storage_provider = length(regexall(".*gov.*", local.aws_region)) > 0 ? "s3gov" : "s3"
}

resource "snowflake_storage_integration" "this" {
  provider = snowflake.storage_integration_role

  name    = "${upper(replace(var.prefix, "-", "_"))}_STORAGE_INTEGRATION"
  type    = "EXTERNAL_STAGE"
  enabled = true
  storage_allowed_locations = concat(
    ["${local.storage_provider}://${aws_s3_bucket.geff_bucket.id}/"],
    [for bucket_id in local.pipeline_bucket_ids : "s3://${bucket_id}/"]
  )
  storage_provider     = local.storage_provider
  storage_aws_role_arn = "arn:${var.arn_format}:iam::${local.account_id}:role/${local.s3_reader_role_name}"
}

resource "snowflake_integration_grant" "this" {
  provider         = snowflake.storage_integration_role
  integration_name = snowflake_storage_integration.this.name

  privilege = "USAGE"
  roles     = var.snowflake_integration_user_roles

  with_grant_option = false
}
