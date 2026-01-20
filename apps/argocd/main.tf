# ===================================================================
# ARGOCD SECRETS - eks-express
# ===================================================================
# Secret para credenciais do ArgoCD (GitHub, admin password, etc.)
# ===================================================================

resource "aws_secretsmanager_secret" "argocd" {
  name                    = "${var.cluster_name}/argocd/credentials"
  description             = "All secrets for ArgoCD - GitHub credentials and other configs"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    var.common_tags,
    {
      Name        = "argocd-credentials"
      SecretType  = "application-config"
      ClusterName = var.cluster_name
    }
  )
}

# Valor inicial do secret (placeholder)
resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id = aws_secretsmanager_secret.argocd.id
  secret_string = jsonencode({
    git_username = "CHANGE_ME"
    git_token    = "CHANGE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
