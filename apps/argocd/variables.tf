# ===================================================================
# VARIABLES - eks-express - ARGOCD
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

variable "cluster_name" {
  type    = string
  default = "eks-express-cluster"
}

variable "secret_recovery_window_days" {
  type    = number
  default = 7
}

variable "common_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "eks-express"
    Application = "argocd"
    ManagedBy   = "terraform"
  }
}
