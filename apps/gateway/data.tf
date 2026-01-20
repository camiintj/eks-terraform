# ===================================================================
# DATA SOURCES - eks-express
# ===================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Remote state do cluster EKS
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "cami-nsse-terraform-state-file"
    key    = "cluster/terraform.tfstate"
    region = "us-east-1"
  }
}
