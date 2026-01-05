########################################
# Moderation Results Table
########################################
resource "aws_dynamodb_table" "moderation_results" {
  name         = "${local.name_prefix}-results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "contentId"
  range_key    = "timestamp"

  attribute {
    name = "contentId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = merge(local.tags, {
    purpose = "Content Moderation Resultsw"
  })
}

