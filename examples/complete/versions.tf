terraform {
  required_version = ">= 1.0.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.64.2"
    }

    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = ">= 0.25.29"
    }
  }
}
