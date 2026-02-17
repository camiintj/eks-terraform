data "terraform_remote_state" "cluster_stack" {
  backend = "s3"

  config = {
    bucket = "<ALTERAR VALOR>"
    key    = "cluster/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "<ALTERAR VALOR>"
    }
}
