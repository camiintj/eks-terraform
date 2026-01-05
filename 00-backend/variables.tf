variable "region" {
  type    = string
  default = "us-east-1"
}

#role criada com as permissoes para o terraform e setada no IAM para ser assumida apenas por usuarios com o external_id correto
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


#tags padroes para todos os recursos criados pelo terraform
variable "tags" {
    type = map(string)
    default = {
        Environment = "production"
        Project     = "not-so-simple-ecommerce"
    }
}

#bucket para armazenar o estado do terrafor
variable "remote_backend" {
  type = object ({
    bucket = string
    state_locking = object({
      dynamodb_table_name = string
      billing_mode = string
      hash_key = string
      
      attribute = object({
        name = string
        type = string
      })
    })
  })

  default = {
    bucket = "cami-nsse-terraform-state-file"
    state_locking = {
      dynamodb_table_name = "nsse-terraform-state-locking"
      billing_mode = "PAY_PER_REQUEST"
      hash_key = "LockID"
      attribute = {
        name = "LockID"
        type = "S"
      }
    }
  }
}