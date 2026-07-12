# Module: vpc

Network foundation for the EKS cluster.

**Provides:** a VPC with public and private subnets across ≥2 AZs, an internet
gateway, and NAT for private-subnet egress. Subnets are tagged for EKS load-balancer
discovery.

| Input | Description | Default |
|-------|-------------|---------|
| `name` | Name prefix for resources | — |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `azs` | AZs to spread across | 2 AZs in `ap-northeast-2` |
| `single_nat_gateway` | One NAT to save cost in non-prod | `true` |

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the VPC |
| `private_subnet_ids` | Private subnet IDs (EKS nodes) |
| `public_subnet_ids` | Public subnet IDs (load balancers) |

> Status: interface defined; resources land in Phase 1.
