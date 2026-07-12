output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = local.cluster_endpoint
}
