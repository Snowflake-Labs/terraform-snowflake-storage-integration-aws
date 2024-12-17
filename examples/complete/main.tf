module "storage_integration" {
  source = "../../"

  # General
  prefix = var.prefix
  env    = var.env

  # AWS
  data_bucket_arns = var.data_bucket_arns

  # Snowflake
  snowflake_integration_user_roles = var.snowflake_integration_user_roles
  bucket_object_ownership_settings = var.bucket_object_ownership_settings

  providers = {
    snowflake.storage_integration_role = snowflake.storage_integration_role
    snowsql.storage_integration_role   = snowsql.storage_integration_role
    aws                                = aws
  }
}
