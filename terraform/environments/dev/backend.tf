# Remote state backend (S3 + DynamoDB lock).
#
# The bucket and lock table are created once by terraform/bootstrap/. Their names
# are account-specific, so they're supplied at init time via a backend-config file
# instead of being committed here:
#
#   terraform init -backend-config=backend.hcl
#
# See backend.hcl.example. backend.hcl itself is git-ignored.

terraform {
  backend "s3" {
    key     = "dev/terraform.tfstate"
    encrypt = true
    # bucket, region, dynamodb_table -> backend.hcl
  }
}
