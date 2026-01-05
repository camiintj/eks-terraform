output "kubernetes_oidc_provider_arn" {
  description = "The ARN of the EKS cluster OIDC provider"
  value       = aws_iam_openid_connect_provider.kubernetes.arn
}

output "kubernetes_oidc_provider_url" {
  description = "The ARN of the EKS cluster OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "eks_cluster_name" {
  description = "The ARN of the EKS cluster OIDC provider"
  value       = aws_eks_cluster.this.name
}