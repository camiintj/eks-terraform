# ===================================================================
# BACKEND CONFIGURATION - eks-express
# ===================================================================

terraform {
  backend "s3" {
    bucket         = "cami-nsse-terraform-state-file"
    key            = "apps/external-dns/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "nsse-terraform-state-locking"
  }
}
