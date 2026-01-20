# ===================================================================
# VARIABLES - eks-express - EXTERNAL SECRETS
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

# ===================================================================
# IAM CONFIGURATION
# ===================================================================

variable "create_iam_role" {
  description = "Criar IAM role para External Secrets Operator"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Nome da IAM role (sem prefixo ne-, será adicionado)"
  type        = string
  default     = "external-secrets"
}

# ===================================================================
# SECRETS MANAGER CONFIGURATION
# ===================================================================

variable "secrets_path_pattern" {
  description = "Padrão de path dos secrets no Secrets Manager que External Secrets pode acessar"
  type        = string
  default     = "ne-stg-eks/*"
}

# ===================================================================
# TAGS
# ===================================================================

variable "common_tags" {
  description = "Tags comuns aplicadas a todos os recursos"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "external-secrets"
    Application = "external-secrets-operator"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}
