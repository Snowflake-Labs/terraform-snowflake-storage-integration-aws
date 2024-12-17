provider "snowsql" {
  alias = "storage_integration_role"

  account  = var.snowflake_account
  role     = var.snowflake_storage_integration_owner_role
  username = "example_user"
}
