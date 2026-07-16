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

output "external_secrets_irsa_role_arn" {
  description = "IRSA role ARN for External Secrets — annotate its ServiceAccount with this."
  value       = var.enable_external_secrets_irsa ? aws_iam_role.external_secrets[0].arn : null
}

output "external_secrets_sa_annotation" {
  description = "Ready-to-apply ServiceAccount annotation wiring ESO to the IRSA role."
  value = var.enable_external_secrets_irsa ? {
    "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets[0].arn
  } : null
}
