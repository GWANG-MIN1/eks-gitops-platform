# Terraform

Infrastructure as Code for the platform. Terraform owns everything *up to and
including* the EKS cluster; in-cluster workloads are handled by GitOps (see
[`../gitops`](../gitops)).

## Layout

```
terraform/
├── bootstrap/        # one-time: S3 + DynamoDB for remote state
├── environments/
│   └── dev/          # root module you actually run `terraform` in
└── modules/
    ├── vpc/          # network foundation
    └── eks/          # cluster + node groups
```

`environments/` hold the composition (which modules, which variables) per stage.
`modules/` are reusable and environment-agnostic.

## Usage

First, once per account, create the remote-state backend:

```bash
cd bootstrap
terraform init && terraform apply
terraform output                # -> bucket + lock table names
```

Then the dev environment:

```bash
cd ../environments/dev
cp backend.hcl.example backend.hcl             # fill in the bootstrap outputs
cp terraform.tfvars.example terraform.tfvars   # then edit values
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
aws eks update-kubeconfig --region ap-northeast-2 --name eks-gitops-dev
# ...learn, then (do this when you're done for the day!):
terraform destroy
```

## Conventions

- **Remote state** lives in S3 with a DynamoDB lock table. The bucket/table are
  created once by [`bootstrap/`](bootstrap); names are passed to `init` via a
  git-ignored `backend.hcl` (see `backend.hcl.example`).
- **No secrets in state files or tfvars.** `*.tfvars` is git-ignored; only
  `*.tfvars.example` is committed.
- Run `terraform fmt -recursive` before committing — CI enforces it.
