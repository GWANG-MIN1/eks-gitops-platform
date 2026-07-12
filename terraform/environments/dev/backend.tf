# Remote state backend.
#
# The bucket and lock table must exist before `terraform init`. Create them once,
# out of band (a small bootstrap script will be added in Phase 1), then fill in the
# values below. Kept as a template so no account-specific names are committed.

terraform {
  backend "s3" {
    # bucket         = "eks-gitops-tfstate-<your-suffix>"
    # key            = "dev/terraform.tfstate"
    # region         = "ap-northeast-2"
    # dynamodb_table = "eks-gitops-tfstate-lock"
    # encrypt        = true
  }
}
