output "state_bucket_name" {
  description = "S3 bucket name — put this in environments/dev/backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "DynamoDB lock table name — put this in environments/dev/backend.hcl."
  value       = aws_dynamodb_table.lock.name
}

output "region" {
  description = "Region the backend resources live in."
  value       = var.region
}
