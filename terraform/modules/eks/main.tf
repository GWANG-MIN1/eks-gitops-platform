# EKS module — control plane + managed node group.
#
# Built on terraform-aws-modules/eks/aws (pinned). Provisions the control plane,
# a managed node group in the private subnets, IRSA (an OIDC provider for
# pod-level IAM), and the core add-ons (VPC CNI, CoreDNS, kube-proxy).
#
# Authentication uses EKS access entries (API mode), so no aws-auth ConfigMap and
# therefore no Kubernetes provider is needed here — the module stays apply-able
# with just AWS credentials.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # Public endpoint so we can reach the API from a workstation / CI. Lock this
  # down with cluster_endpoint_public_access_cidrs for anything beyond a demo.
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Grant the identity running Terraform cluster-admin via an access entry, so
  # kubectl works immediately after apply without extra RBAC wiring.
  enable_cluster_creator_admin_permissions = true

  # IRSA: create the OIDC provider so workloads can assume IAM roles.
  enable_irsa = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  tags = var.tags
}
