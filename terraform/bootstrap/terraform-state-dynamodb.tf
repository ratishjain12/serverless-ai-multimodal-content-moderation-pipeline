
########################################
# Terraform State Lock - DynamoDB Table
########################################

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    ManagedBy  = "terraform"
    Purpose    = "terraform-state-locking"
  }
}
