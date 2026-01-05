resource "aws_dynamodb_table" "this" {
  name             = var.remote_backend.state_locking.dynamodb_table_name
  hash_key         = var.remote_backend.state_locking.hash_key
  billing_mode     = var.remote_backend.state_locking.billing_mode

    attribute {
    name = var.remote_backend.state_locking.attribute.name
    type = var.remote_backend.state_locking.attribute.type
  }
}