# ===================================================================
# PROVIDER CONFIGURATION - eks-express
# ===================================================================

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn    = var.assume_role.role_arn
    external_id = var.assume_role.external_id
  }

  default_tags {
    tags = var.common_tags
  }
}
