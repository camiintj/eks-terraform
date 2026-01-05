variable "region" {
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

variable "tags" {
    type = object({
      Project     = string
      Environment = string 
    })
    default = {
        Project     = "eks-express"
        Environment = "production"
    }
}

variable "karpenter" {
    type = object({
        controller_role_name = string
        controller_policy_name = string
    })
    default = {
        controller_role_name = "KarpenterControllerRole"
        controller_policy_name = "KarpenterControllerPolicy"
    }
  
}

