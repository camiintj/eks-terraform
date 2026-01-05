terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "cami-nsse-terraform-state-file"
    key    = "karpenter-auto-scaling/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "nsse-terraform-state-locking"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  assume_role {
    role_arn    = var.assume_role.role_arn
    external_id = var.assume_role.external_id
  }
}



