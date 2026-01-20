# ===================================================================
# TERRAFORM VARIABLES - EXTERNAL SECRETS - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# IAM Configuration
create_iam_role = true
iam_role_name   = "external-secrets"

# Secrets Manager Configuration
secrets_path_pattern = "eks-express/*"

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "external-secrets-operator"
  ManagedBy   = "terraform"
}
