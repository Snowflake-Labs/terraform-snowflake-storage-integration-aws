# As mentioned here from the tf aws provider:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
# The following variables you need to set up in the environment:
# export AWS_ACCESS_KEY_ID="anaccesskey"
# export AWS_SECRET_ACCESS_KEY="asecretkey"
# export AWS_DEFAULT_REGION="us-west-2"

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      environment = var.env
    }
  }
}
