# ===================================================================
# TERRAFORM VARIABLES - GATEWAY - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# SQS Configuration
inbound_queue_name         = "gateway-inbound.fifo"
outbound_queue_name        = "gateway-outbound.fifo"
message_retention_seconds  = 1209600
visibility_timeout_seconds = 300
receive_wait_time_seconds  = 20
max_message_size           = 262144
dlq_max_receive_count      = 3

# S3 Configuration
audit_bucket_name                 = "eks-express-gateway-audit-logs"
lifecycle_transition_ia_days      = 90
lifecycle_transition_glacier_days = 365
lifecycle_expiration_days         = 2555

# IAM Configuration
create_iam_role = true
iam_role_name   = "gateway-eks-workload"

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "gateway"
  ManagedBy   = "terraform"
}
