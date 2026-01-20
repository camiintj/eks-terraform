# ===================================================================
# ARGOCD IMAGE UPDATER - IRSA CONFIGURATION
# ===================================================================
# IAM Role e Policies para ArgoCD Image Updater acessar ECR via IRSA
# (IAM Roles for Service Accounts)
#
# Image Updater precisa de acesso a:
# - ECR: GetAuthorizationToken, BatchGetImage, DescribeImages para verificar novas versões
# ===================================================================

# ===================================================================
# IAM ROLE PARA ARGOCD IMAGE UPDATER (IRSA)
# ===================================================================

resource "aws_iam_role" "argocd_image_updater" {
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
      Name        = "eks-express-argocd-image-updater"
      Description = "IAM Role para ArgoCD Image Updater acessar ECR via IRSA"
    }
  )
}

# ===================================================================
# IAM POLICY - ECR READ ACCESS
# ===================================================================
# Image Updater precisa de permissão para:
# - Obter token de autenticação do ECR
# - Listar e descrever imagens
# - Baixar metadados das imagens (layers)

resource "aws_iam_policy" "ecr_read_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "eks-express-argocd-image-updater-ecr-read"
  description = "Permite ArgoCD Image Updater ler imagens do ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ImageUpdaterECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ImageUpdaterECRRead"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:GetRepositoryPolicy"
        ]
        Resource = var.ecr_repository_arns != null ? var.ecr_repository_arns : [
          "arn:aws:ecr:${local.region}:${local.account_id}:repository/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# ===================================================================
# ATTACH POLICY TO ROLE
# ===================================================================

resource "aws_iam_role_policy_attachment" "ecr_read_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.argocd_image_updater[0].name
  policy_arn = aws_iam_policy.ecr_read_access[0].arn
}

# ===================================================================
# AWS SECRETS MANAGER - ARGOCD IMAGE UPDATER
# ===================================================================
# Secret para armazenar todas as credenciais do ArgoCD Image Updater
# Seguindo o padrão: ne-stg-eks/{aplicacao}
# 
# Conteúdo do secret (JSON):
# {
#   "GIT_USERNAME": "usuario-github",
#   "GIT_PASSWORD": "ghp_token_github"
# }

resource "aws_secretsmanager_secret" "argocd_image_updater" {
  count = var.create_secret ? 1 : 0

  name        = "eks-express-cluster/argocd-image-updater"
  description = "ArgoCD Image Updater credentials - Git username and token for write-back"

  tags = {
    Name        = "argocd-image-updater"
    Environment = "staging"
    Application = "argocd-image-updater"
    ManagedBy   = "terraform"
  }
}

# ===================================================================
# SECRET VERSION - ARGOCD IMAGE UPDATER
# ===================================================================
# IMPORTANTE: Após criar o secret, você precisa adicionar o valor manualmente:
#
# aws secretsmanager put-secret-value \
#   --secret-id ne-stg-eks/argocd-image-updater \
#   --secret-string '{
#     "GIT_USERNAME": "seu-usuario-github",
#     "GIT_PASSWORD": "ghp_seu_token_aqui"
#   }'
#
# Ou via console AWS: Secrets Manager > ne-stg-eks/argocd-image-updater > Retrieve secret value > Edit

resource "aws_secretsmanager_secret_version" "argocd_image_updater" {
  count = var.create_secret && var.secret_values != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.argocd_image_updater[0].id
  secret_string = jsonencode(var.secret_values)
}
