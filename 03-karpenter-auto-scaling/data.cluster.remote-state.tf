data "terraform_remote_state" "cluster_stack" {
  backend = "s3"

  config = {
    bucket = "cami-nsse-terraform-state-file"
    key    = "cluster/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "nsse-terraform-state-locking"
    }
}
