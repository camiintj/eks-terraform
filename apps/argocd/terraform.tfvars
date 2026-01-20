# ===================================================================
# TERRAFORM VARIABLES - ARGOCD - eks-express
# ===================================================================

aws_region   = "us-east-1"
environment  = "production"
cluster_name = "eks-express-cluster"

# Secrets Manager - 7 dias de recovery
secret_recovery_window_days = 7

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "argocd"
  ManagedBy   = "terraform"
}
