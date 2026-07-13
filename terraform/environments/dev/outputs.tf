output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN (used by IRSA-enabled workloads)."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "configure_kubectl" {
  description = "Command to point kubectl at this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
