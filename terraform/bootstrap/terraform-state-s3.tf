########################################
# Terraform State S3 Bucket
########################################

resource "aws_s3_bucket" "terraform_state" {
  bucket = "content-moderation-tf-state"

  tags = {
    Name        = "content-moderation-tf-state"
    ManagedBy  = "terraform"
    Purpose    = "terraform-state-storage"
  }
}

########################################
# Enable Versioning (MANDATORY)
########################################

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################################
# Enable Server-Side Encryption
########################################

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

########################################
# Block Public Access (MANDATORY)
########################################

resource "aws_s3_bucket_public_access_block" "terraform_state_block_public" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
