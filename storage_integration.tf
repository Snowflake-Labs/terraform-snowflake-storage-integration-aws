locals {
  storage_provider_map        = lookup(local.snowflake_storage_provider_maps, local.aws_partition, null)
  snowflake_storage_provider  = local.storage_provider_map["snowflake_storage_provider"]
  terraform_resource_provider = local.storage_provider_map["terraform_resource_provider"]

  storage_integration_name = "${upper(replace(var.prefix, "-", "_"))}_STORAGE_INTEGRATION"

  pipeline_bucket_ids = [
    for bucket_arn in var.data_bucket_arns : element(split(":::", bucket_arn), 1)
  ]
  storage_allowed_locations = concat(
    ["${local.snowflake_storage_provider}://${aws_s3_bucket.geff_bucket.id}/"],
    [for bucket_id in local.pipeline_bucket_ids : "${local.snowflake_storage_provider}://${bucket_id}/"]
  )

  storage_allowed_locations_snowsql = join(",", [for i in local.storage_allowed_locations : join("", ["'", i, "'"])])
}

resource "snowflake_storage_integration" "this" {
  count    = local.terraform_resource_provider == "snowflake" ? 1 : 0
  provider = snowflake.storage_integration_role

  name    = local.storage_integration_name
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_allowed_locations = local.storage_allowed_locations
  storage_provider          = local.snowflake_storage_provider
  storage_aws_role_arn      = "arn:${local.aws_partition}:iam::${local.account_id}:role/${local.s3_reader_role_name}"
}

## Create Snowflake storage integration with SnowSQL Terraform provider if the official Snowflake Terraform provider not yet support the specific sovereign cloud.
resource "snowsql_exec" "snowflake_storage_integration" {
  count    = local.terraform_resource_provider == "snowsql" ? 1 : 0
  provider = snowsql.storage_integration_role

  create {
    statements = <<-EOT
      CREATE OR REPLACE STORAGE INTEGRATION "${local.storage_integration_name}"
	TYPE=EXTERNAL_STAGE
	STORAGE_PROVIDER='${local.snowflake_storage_provider}'
	STORAGE_AWS_ROLE_ARN="arn:${local.aws_partition}:iam::${local.account_id}:role/${local.s3_reader_role_name}"
	ENABLED=true
	STORAGE_ALLOWED_LOCATIONS=(${local.storage_allowed_locations_snowsql});
    EOT
  }

  read {
    statements = "DESCRIBE STORAGE INTEGRATION ${local.storage_integration_name};"
  }

  delete {
    statements = "DROP INTEGRATION ${local.storage_integration_name};"
  }
}

locals {
  storage_integration_user_arn = local.terraform_resource_provider == "snowflake" ? snowflake_storage_integration.this[0].storage_aws_iam_user_arn : [for map in jsondecode(nonsensitive(snowsql_exec.snowflake_storage_integration[0].read_results)): map if map.property == "STORAGE_AWS_IAM_USER_ARN"][0]["property_value"]

  storage_integration_external_id = local.terraform_resource_provider == "snowflake" ? snowflake_storage_integration.this[0].storage_aws_external_id : [for map in jsondecode(nonsensitive(snowsql_exec.snowflake_storage_integration[0].read_results)): map if map.property == "STORAGE_AWS_EXTERNAL_ID"][0]["property_value"]
}

resource "snowflake_integration_grant" "this" {
  provider         = snowflake.storage_integration_role
  integration_name = local.storage_integration_name

  privilege = "USAGE"
  roles     = var.snowflake_integration_user_roles

  with_grant_option = false

  depends_on = [
    snowflake_storage_integration.this,
    snowsql_exec.snowflake_storage_integration,
  ]
}
