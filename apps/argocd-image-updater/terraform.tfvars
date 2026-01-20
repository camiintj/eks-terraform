# ===================================================================
# TERRAFORM VARIABLES - ARGOCD IMAGE UPDATER - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# IAM Configuration
create_iam_role = true
iam_role_name   = "argocd-image-updater"

# ECR Configuration (null = permite todos os repositórios)
ecr_repository_arns = null

# Secret Configuration
create_secret = true
secret_values = null

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "argocd-image-updater"
  ManagedBy   = "terraform"
}
