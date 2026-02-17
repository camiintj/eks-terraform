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
    role_arn    = "<ALTERAR VALOR>"
    external_id = "<ALTERAR VALOR>"
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

variable "eks_cluster" {
  type = object({
    name                        = string
    role_name                   = string
    version                     = string
    enabled_cluster_log_types   = list(string)
    
    access_config               = object({
      authentication_mode = string  
    })

    node_group = object({
    name            = string
    role_name       = string
    instance_types  = list(string)
    capacity_type   = string
    ami_type        = string

    scaling_config = object({
        desired_size  = number
        max_size      = number
        min_size      = number
        })

    update_config = object({
        max_unavailable = number
        })
    })
  })



    default = {
        name                      = "eks-express-cluster"
        role_name                 = "eks-express-cluster-role"
        version                   = "1.34"
        enabled_cluster_log_types = [
        "api",
        "audit",
        "authenticator",
        "controllerManager",
        "scheduler",
        ]
        access_config = {
        authentication_mode = "API_AND_CONFIG_MAP"
        }

        node_group = {
        name              = "eks-express-node-group"
        role_name         = "eks-express-node-group-role"
        instance_types    = ["t3.small"]
        capacity_type     = "ON_DEMAND"
        ami_type          = "BOTTLEROCKET_x86_64"

        scaling_config = {
            desired_size  = 2
            max_size      = 2
            min_size      = 2
            }

        update_config = {
            max_unavailable = 1
            }
        }
    }
}

variable "custom_domain" {
  type = string
  default = "<ALTERAR VALOR>"
}