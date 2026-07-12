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
| `node_desired_size` | Desired node count | `2` |

| Output | Description |
|--------|-------------|
| `cluster_name` | Cluster name |
| `cluster_endpoint` | API server endpoint |

> Status: interface defined; resources land in Phase 1.
