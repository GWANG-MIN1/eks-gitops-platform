# Dev environment composition.
#
# Wires the reusable modules together: the VPC provides the network, the EKS
# module builds the cluster inside it. Sizing/cost knobs are surfaced as
# variables so this stays cheap to spin up and tear down daily.

module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.cluster_name}-vpc"
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}
