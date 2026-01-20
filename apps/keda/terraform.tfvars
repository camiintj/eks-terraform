# ===================================================================
# TERRAFORM VARIABLES - KEDA - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# IAM Configuration
create_iam_role = true
iam_role_name   = "keda-operator"

# SQS Configuration (padrão de filas que o KEDA pode monitorar)
sqs_queue_pattern = "*"

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "keda-operator"
  ManagedBy   = "terraform"
}
