# ===================================================================
# OUTPUTS - EXTERNAL-DNS IRSA
# ===================================================================

# ===================================================================
# IAM OUTPUTS
# ===================================================================

output "iam_role_arn" {
  description = "ARN da IAM Role para External DNS"
  value       = var.create_iam_role ? aws_iam_role.external_dns[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para External DNS"
  value       = var.create_iam_role ? aws_iam_role.external_dns[0].name : null
}

output "route53_policy_arn" {
  description = "ARN da policy Route53"
  value       = var.create_iam_role ? aws_iam_policy.route53_access[0].arn : null
}

# ===================================================================
# KUBERNETES CONFIGURATION
# ===================================================================

output "k8s_service_account_annotation" {
  description = "Anotação para adicionar ao ServiceAccount Kubernetes do External DNS"
  value       = var.create_iam_role ? "eks.amazonaws.com/role-arn: ${aws_iam_role.external_dns[0].arn}" : null
}

output "k8s_namespace" {
  description = "Namespace Kubernetes do External DNS"
  value       = local.k8s_namespace
}

output "k8s_service_account" {
  description = "Nome do ServiceAccount Kubernetes do External DNS"
  value       = local.k8s_service_account
}

# ===================================================================
# CONFIGURATION SUMMARY
# ===================================================================

output "configuration_summary" {
  description = "Resumo da configuração External DNS IRSA"
  value = var.create_iam_role ? {
    iam_role_arn         = aws_iam_role.external_dns[0].arn
    namespace            = local.k8s_namespace
    service_account      = local.k8s_service_account
    route53_hosted_zones = var.route53_hosted_zones
  } : null
}
