# ===================================================================
# OUTPUTS - YACE IRSA
# ===================================================================

# ===================================================================
# IAM OUTPUTS
# ===================================================================

output "iam_role_arn" {
  description = "ARN da IAM Role para YACE"
  value       = var.create_iam_role ? aws_iam_role.yace[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para YACE"
  value       = var.create_iam_role ? aws_iam_role.yace[0].name : null
}

output "cloudwatch_policy_arn" {
  description = "ARN da policy CloudWatch"
  value       = var.create_iam_role ? aws_iam_policy.cloudwatch_read[0].arn : null
}

output "resource_discovery_policy_arn" {
  description = "ARN da policy Resource Discovery"
  value       = var.create_iam_role ? aws_iam_policy.resource_discovery[0].arn : null
}

output "sqs_metadata_policy_arn" {
  description = "ARN da policy SQS Metadata"
  value       = var.create_iam_role ? aws_iam_policy.sqs_metadata[0].arn : null
}

# ===================================================================
# KUBERNETES CONFIGURATION
# ===================================================================

output "k8s_service_account_annotation" {
  description = "Anotação para adicionar ao ServiceAccount Kubernetes do YACE"
  value       = var.create_iam_role ? "eks.amazonaws.com/role-arn: ${aws_iam_role.yace[0].arn}" : null
}

output "k8s_namespace" {
  description = "Namespace Kubernetes do YACE"
  value       = local.k8s_namespace
}

output "k8s_service_account" {
  description = "Nome do ServiceAccount Kubernetes do YACE"
  value       = local.k8s_service_account
}

# ===================================================================
# CONFIGURATION SUMMARY
# ===================================================================

output "configuration_summary" {
  description = "Resumo da configuração YACE IRSA"
  value = var.create_iam_role ? {
    iam_role_arn    = aws_iam_role.yace[0].arn
    namespace       = local.k8s_namespace
    service_account = local.k8s_service_account
    region          = local.region
  } : null
}
