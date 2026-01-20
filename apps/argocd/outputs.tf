# ===================================================================
# OUTPUTS - ARGOCD - eks-express
# ===================================================================

output "argocd_secret_name" {
  description = "Nome do secret ArgoCD no Secrets Manager"
  value       = aws_secretsmanager_secret.argocd.name
}

output "argocd_secret_arn" {
  description = "ARN do secret ArgoCD no Secrets Manager"
  value       = aws_secretsmanager_secret.argocd.arn
}

output "setup_instructions" {
  description = "Instruções para configurar o secret ArgoCD"
  value       = <<-EOT
    # ===================================================================
    # SETUP ARGOCD SECRETS
    # ===================================================================

    # Atualizar secret com suas credenciais:
    aws secretsmanager put-secret-value \
      --secret-id ${aws_secretsmanager_secret.argocd.name} \
      --secret-string '{"git_username": "SEU_USUARIO", "git_token": "SEU_TOKEN"}' \
      --region us-east-1
  EOT
}
