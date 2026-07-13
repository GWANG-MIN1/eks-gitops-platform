variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "ap-northeast-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state. Defaults to eks-gitops-tfstate-<account-id> for global uniqueness."
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
  default     = "eks-gitops-tfstate-lock"
}
