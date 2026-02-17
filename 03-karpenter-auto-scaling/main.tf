terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {                                                               
      source  = "hashicorp/helm"                                           
      version = "~> 3.0"                                                   
    }  
  }

  backend "s3" {
    bucket = "<ALTERAR VALOR>"
    key    = "karpenter-auto-scaling/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "<ALTERAR VALOR>"
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

provider "helm" {
  kubernetes = {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(local.eks_cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
      command     = "aws"
    }
  }
}

