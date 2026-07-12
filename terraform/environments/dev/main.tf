# Dev environment composition.
#
# Wires the reusable modules together. Module internals are being implemented in
# Phase 1 (see docs/roadmap.md) — the call sites and variable contracts are defined
# here first so the shape of the environment is clear.

module "vpc" {
  source = "../../modules/vpc"

  name     = "${var.cluster_name}-vpc"
  vpc_cidr = var.vpc_cidr
  # azs, subnet layout, NAT strategy -> module defaults (Phase 1)
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
