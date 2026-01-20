# ===================================================================
# OUTPUTS - KEDA OPERATOR IRSA
# ===================================================================

# ===================================================================
# IAM OUTPUTS
# ===================================================================

output "iam_role_arn" {
  description = "ARN da IAM Role para KEDA Operator"
  value       = var.create_iam_role ? aws_iam_role.keda_operator[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para KEDA Operator"
  value       = var.create_iam_role ? aws_iam_role.keda_operator[0].name : null
}

output "sqs_policy_arn" {
  description = "ARN da policy SQS"
  value       = var.create_iam_role ? aws_iam_policy.sqs_read[0].arn : null
}

# ===================================================================
# KUBERNETES CONFIGURATION
# ===================================================================

output "k8s_service_account_annotation" {
  description = "Anotação para adicionar ao ServiceAccount Kubernetes do KEDA"
  value       = var.create_iam_role ? "eks.amazonaws.com/role-arn: ${aws_iam_role.keda_operator[0].arn}" : null
}

output "k8s_namespace" {
  description = "Namespace Kubernetes do KEDA"
  value       = local.k8s_namespace
}

output "k8s_service_account" {
  description = "Nome do ServiceAccount Kubernetes do KEDA"
  value       = local.k8s_service_account
}

# ===================================================================
# CONFIGURATION SUMMARY
# ===================================================================

output "configuration_summary" {
  description = "Resumo da configuração KEDA IRSA"
  value = var.create_iam_role ? {
    iam_role_arn      = aws_iam_role.keda_operator[0].arn
    namespace         = local.k8s_namespace
    service_account   = local.k8s_service_account
    sqs_queue_pattern = var.sqs_queue_pattern
  } : null
}
