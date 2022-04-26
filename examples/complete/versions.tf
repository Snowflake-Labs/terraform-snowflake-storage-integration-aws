terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }

    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.32.0"
    }
  }
}
