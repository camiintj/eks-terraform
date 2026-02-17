output "kubernetes_oidc_provider_arn" {
  description = "The ARN of the EKS cluster OIDC provider"
  value       = aws_iam_openid_connect_provider.kubernetes.arn
}

output "kubernetes_oidc_provider_url" {
  description = "The URL of the EKS cluster OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster "
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_security_group" {
  description = "The SG of the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_node_group_name" {
  value = aws_eks_node_group.this.node_group_name
  
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
  
}

output "eks_cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data

}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "karpenter_node_role_name"{
  value = aws_iam_role.eks_cluster_node_group.name
}



