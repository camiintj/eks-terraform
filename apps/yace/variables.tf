# ===================================================================
# VARIABLES - eks-express - YACE
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

variable "create_iam_role" {
  type    = bool
  default = true
}

variable "iam_role_name" {
  type    = string
  default = "yace"
}

variable "common_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "eks-express"
    Application = "yace"
    ManagedBy   = "terraform"
  }
}
