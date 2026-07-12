# VPC module — network foundation for the EKS cluster.
#
# TODO (Phase 1): implement public/private subnets across the AZs, an internet
# gateway, NAT gateway(s), and route tables. Subnets will carry the EKS discovery
# tags (kubernetes.io/role/elb, .../internal-elb) so load balancers land correctly.
#
# Likely built on terraform-aws-modules/vpc/aws to avoid reinventing subnet math;
# pinned and reviewed rather than copy-pasted.

locals {
  # Placeholders until resources land — keeps the module's output contract stable.
  vpc_id             = ""
  private_subnet_ids = []
  public_subnet_ids  = []
}
