output "vpc_id" {
  description = "ID of the VPC."
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where EKS nodes run)."
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (where load balancers run)."
  value       = local.public_subnet_ids
}
