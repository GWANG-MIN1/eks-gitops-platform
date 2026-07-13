# VPC module — network foundation for the EKS cluster.
#
# Built on terraform-aws-modules/vpc/aws (pinned) instead of hand-rolling subnet
# math and route tables. Provides public/private subnets across the given AZs, an
# internet gateway, and NAT for private-subnet egress.
#
# Subnets carry the EKS load-balancer discovery tags so the AWS Load Balancer
# Controller can place internet-facing LBs in public subnets and internal LBs in
# private subnets automatically:
#   public  -> kubernetes.io/role/elb
#   private -> kubernetes.io/role/internal-elb

locals {
  # Deterministic, non-overlapping subnet layout derived from the VPC CIDR:
  #   private -> /20 blocks (10.0.0.0/20, 10.0.16.0/20, ...) for nodes/pods
  #   public  -> /24 blocks (10.0.48.0/24, 10.0.49.0/24, ...) for load balancers
  private_subnets = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 48)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = var.name
  cidr = var.vpc_cidr
  azs  = var.azs

  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  # Egress for private subnets. A single NAT gateway keeps non-prod cheap; flip
  # single_nat_gateway to false for one-NAT-per-AZ resilience in prod.
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  # Required for EKS: nodes and the API rely on DNS names within the VPC.
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
