

output "storage_integration_name" {
  description = "Name of Storage integration"
  value       = module.storage_integration.storage_integration_name
}

output "bucket_url" {
  description = "GEFF S3 Bucket URL"
  value       = module.storage_integration.bucket_url
}

output "sns_topic_arn" {
  description = "GEFF S3 SNS Topic to use while creating the Snowflake PIPE."
  value       = module.storage_integration.sns_topic_arn
}
