# Module: eks

EKS control plane and a managed node group.

**Provides:** an EKS cluster at the requested Kubernetes version, a managed node
group in private subnets, IRSA (OIDC) for pod-level IAM, and core add-ons.

| Input | Description | Default |
|-------|-------------|---------|
| `cluster_name` | Cluster name | — |
| `kubernetes_version` | Control plane version | `1.30` |
| `vpc_id` | Target VPC | — |
| `private_subnet_ids` | Subnets for node group | — |
| `node_instance_types` | Node instance types | `["t3.medium"]` |
| `node_capacity_type` | `SPOT` or `ON_DEMAND` | `SPOT` |
| `node_desired_size` | Desired node count | `2` |
| `node_min_size` | Min node count | `1` |
| `node_max_size` | Max node count | `3` |
| `tags` | Extra tags for cluster resources | `{}` |

| Output | Description |
|--------|-------------|
| `cluster_name` | Cluster name |
| `cluster_endpoint` | API server endpoint |
| `cluster_certificate_authority_data` | Base64 CA cert |
| `cluster_security_group_id` | Control-plane security group |
| `oidc_provider_arn` | IAM OIDC provider ARN (for IRSA) |
| `oidc_provider` | OIDC issuer URL, no scheme (IRSA sub/aud conditions) |

Built on [`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) (pinned `~> 20.24`). Uses EKS access entries (API auth mode), so no Kubernetes provider or `aws-auth` ConfigMap is required. Node group defaults to **SPOT** capacity to keep the dev cluster cheap.

> Status: implemented (Phase 1). Validated with `terraform validate`; not yet apply-tested against a live account.
