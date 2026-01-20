# ===================================================================
# VARIABLES - eks-express - GATEWAY
# ===================================================================

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "assume_role" {
  type = object({
    role_arn    = string
    external_id = string
  })
  default = {
    role_arn    = "arn:aws:iam::005988779053:role/terraform_role"
    external_id = "20edb746-4470-4314-9777-1c0fd2025b24"
  }
}

variable "environment" {
  type    = string
  default = "production"
}

# SQS Configuration
variable "inbound_queue_name" {
  type    = string
  default = "gateway-inbound.fifo"
}

variable "outbound_queue_name" {
  type    = string
  default = "gateway-outbound.fifo"
}

variable "message_retention_seconds" {
  type    = number
  default = 1209600
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 300
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 20
}

variable "max_message_size" {
  type    = number
  default = 262144
}

variable "dlq_max_receive_count" {
  type    = number
  default = 3
}

# S3 Configuration
variable "audit_bucket_name" {
  type = string
}

variable "lifecycle_transition_ia_days" {
  type    = number
  default = 90
}

variable "lifecycle_transition_glacier_days" {
  type    = number
  default = 365
}

variable "lifecycle_expiration_days" {
  type    = number
  default = 2555
}

# IAM Configuration
variable "create_iam_role" {
  type    = bool
  default = true
}

variable "iam_role_name" {
  type    = string
  default = "gateway-eks-workload"
}

# Secrets Manager
variable "secret_recovery_window_days" {
  type    = number
  default = 7
}

# Tags
variable "common_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "eks-express"
    Application = "gateway"
    ManagedBy   = "terraform"
  }
}
