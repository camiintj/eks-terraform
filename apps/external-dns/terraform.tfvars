# ===================================================================
# TERRAFORM VARIABLES - EXTERNAL-DNS - eks-express
# ===================================================================

aws_region  = "us-east-1"
environment = "production"

# IAM Configuration
create_iam_role = true
iam_role_name   = "external-dns"

# Route53 Configuration
route53_hosted_zones = [
  "Z0518172PNKO5F6UHUDL", # camicamp.com.br
]

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "eks-express"
  Application = "external-dns"
  ManagedBy   = "terraform"
}
