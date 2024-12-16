terraform {
  required_version = ">= 1.4.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.72.0"
    }

    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.73.0"

      configuration_aliases = [
        snowflake.storage_integration_role,
      ]
    }

    snowsql = {
      source  = "aidanmelen/snowsql"
      version = ">= 1.3.3"

      configuration_aliases = [
        snowsql.storage_integration_role,
      ]
    }

  }
}
