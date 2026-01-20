# ===================================================================
# OUTPUTS
# ===================================================================

output "iam_role_arn" {
  description = "ARN da IAM role criada para ArgoCD Image Updater"
  value       = var.create_iam_role ? aws_iam_role.argocd_image_updater[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM role criada"
  value       = var.create_iam_role ? aws_iam_role.argocd_image_updater[0].name : null
}

output "iam_policy_arn" {
  description = "ARN da IAM policy de acesso ao ECR"
  value       = var.create_iam_role ? aws_iam_policy.ecr_read_access[0].arn : null
}

output "service_account_annotation" {
  description = "Annotation para adicionar ao ServiceAccount do Kubernetes"
  value       = var.create_iam_role ? "eks.amazonaws.com/role-arn: ${aws_iam_role.argocd_image_updater[0].arn}" : null
}

output "secret_arn" {
  description = "ARN do secret do ArgoCD Image Updater no Secrets Manager"
  value       = var.create_secret ? aws_secretsmanager_secret.argocd_image_updater[0].arn : null
}

output "secret_name" {
  description = "Nome do secret do ArgoCD Image Updater no Secrets Manager"
  value       = var.create_secret ? aws_secretsmanager_secret.argocd_image_updater[0].name : null
}
