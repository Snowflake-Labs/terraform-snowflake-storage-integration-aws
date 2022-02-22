terraform {
  required_version = ">= 1.0.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }

    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.36"

      configuration_aliases = [
        snowflake.storage_integration
      ]
    }
  }
}
