# ===================================================================
# EXTERNAL SECRETS OPERATOR - IRSA CONFIGURATION
# ===================================================================
# IAM Role e Policies para External Secrets Operator acessar AWS Secrets Manager
# via IRSA (IAM Roles for Service Accounts)
#
# External Secrets precisa de acesso a:
# - Secrets Manager: GetSecretValue, DescribeSecret
# ===================================================================

# ===================================================================
# IAM ROLE PARA EXTERNAL SECRETS OPERATOR (IRSA)
# ===================================================================

resource "aws_iam_role" "external_secrets" {
  count = var.create_iam_role ? 1 : 0

  name = "eks-express-${var.iam_role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:${local.k8s_namespace}:${local.k8s_service_account}"
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "eks-express-external-secrets"
      Description = "IAM Role para External Secrets Operator acessar Secrets Manager via IRSA"
    }
  )
}

# ===================================================================
# IAM POLICY - SECRETS MANAGER ACCESS
# ===================================================================

resource "aws_iam_policy" "secrets_manager_read" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-external-secrets-secretsmanager-read"
  description = "Permite External Secrets Operator ler secrets do Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ExternalSecretsSecretsManagerReadAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.secrets_path_pattern}"
        ]
      },
      {
        Sid      = "ExternalSecretsListSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# ATTACH POLICY TO ROLE
# ===================================================================

resource "aws_iam_role_policy_attachment" "secrets_manager_read" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.secrets_manager_read[0].arn
}
