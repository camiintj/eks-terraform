# ===================================================================
# TERRAFORM VARIABLES - YACE - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# IAM Configuration
create_iam_role = true
iam_role_name   = "yace"

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "yace-cloudwatch-exporter"
  ManagedBy   = "terraform"
}
