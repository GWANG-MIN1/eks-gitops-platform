# Bootstrap: remote-state backend

Creates the S3 bucket and DynamoDB table that back Terraform's remote state, so
the environments can use the S3 backend. This is the one piece that can't live in
remote state itself (chicken-and-egg), so it keeps **local** state.

Run once per AWS account:

```bash
cd terraform/bootstrap
terraform init
terraform apply
terraform output
```

Then copy the outputs into [`../environments/dev/backend.hcl`](../environments/dev)
(see `backend.hcl.example`) and init the dev environment with them:

```bash
cd ../environments/dev
terraform init -backend-config=backend.hcl
```

## What it creates

| Resource | Purpose | Notes |
|----------|---------|-------|
| S3 bucket | Stores `terraform.tfstate` | Versioned, AES256-encrypted, public access blocked, `prevent_destroy` |
| DynamoDB table | State locking | `PAY_PER_REQUEST`, hash key `LockID` |

The bucket name defaults to `eks-gitops-tfstate-<account-id>` for global
uniqueness; override with `state_bucket_name` if you prefer.

> This is infrastructure you create once and leave alone — it is **not** part of
> the daily destroy/apply cycle.
