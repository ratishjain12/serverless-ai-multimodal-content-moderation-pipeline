########################################
# Input Content Bucket
########################################
resource "aws_s3_bucket" "content_input" {
  bucket = "${local.name_prefix}-input"

  tags = merge(local.tags, {
    Purpose = "Content Input"
  })
}

resource "aws_s3_bucket_versioning" "content_input_versioning" {
  bucket = aws_s3_bucket.content_input.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "content_input_block_public" {
  bucket = aws_s3_bucket.content_input.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# Moderation Results Bucket
########################################
resource "aws_s3_bucket" "content_results" {
  bucket = "${local.name_prefix}-results"

  tags = merge(local.tags, {
    Purpose = "Content Moderation Results"
  })
}

resource "aws_s3_bucket_versioning" "content_results_versioning" {
  bucket = aws_s3_bucket.content_results.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "content_results_block_public" {
  bucket = aws_s3_bucket.content_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_notification" "s3_ingestion_notify" {
  bucket = aws_s3_bucket.content_input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingestion_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.content_input.arn
}