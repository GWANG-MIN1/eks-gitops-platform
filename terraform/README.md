# Terraform

Infrastructure as Code for the platform. Terraform owns everything *up to and
including* the EKS cluster; in-cluster workloads are handled by GitOps (see
[`../gitops`](../gitops)).

## Layout

```
terraform/
├── environments/
│   └── dev/          # root module you actually run `terraform` in
└── modules/
    ├── vpc/          # network foundation
    └── eks/          # cluster + node groups
```

`environments/` hold the composition (which modules, which variables) per stage.
`modules/` are reusable and environment-agnostic.

## Usage

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # then edit values
terraform init
terraform plan
terraform apply
# ...learn, then:
terraform destroy
```

## Conventions

- **Remote state** lives in S3 with a DynamoDB lock table (see `backend.tf`). The
  bucket/table are created once, out of band, before the first `init`.
- **No secrets in state files or tfvars.** `*.tfvars` is git-ignored; only
  `*.tfvars.example` is committed.
- Run `terraform fmt -recursive` before committing — CI enforces it.
