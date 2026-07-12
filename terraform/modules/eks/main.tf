# EKS module — control plane + managed node group.
#
# TODO (Phase 1): provision the EKS control plane, a managed node group in the
# private subnets, IRSA (OIDC provider) for workload identity, and the core add-ons
# (VPC CNI, CoreDNS, kube-proxy). Likely built on terraform-aws-modules/eks/aws,
# pinned and reviewed.

locals {
  # Placeholders until resources land — keeps the module's output contract stable.
  cluster_name     = var.cluster_name
  cluster_endpoint = ""
}
