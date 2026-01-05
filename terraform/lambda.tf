########################################
# Text Moderation Lambda
########################################
resource "aws_lambda_function" "text_moderation" {
  function_name = "${local.name_prefix}-text-moderation"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 512

  filename         = "../services/TextModeration/TextModeration.zip"
  source_code_hash = filebase64sha256("../services/TextModeration/TextModeration.zip")

  environment {
    variables = {
      env           = var.environment
      INPUT_BUCKET  = aws_s3_bucket.content_input.bucket
      RESULTS_BUCKET = aws_s3_bucket.content_results.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.moderation_results.name
      language      = "en"
    }
  }

  tags = local.tags
}

########################################
# Image Moderation Lambda
########################################
resource "aws_lambda_function" "image_moderation" {
  function_name = "${local.name_prefix}-image-moderation"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 1024

  filename         = "../services/ImageModeration/ImageModeration.zip"
  source_code_hash = filebase64sha256("../services/ImageModeration/ImageModeration.zip")

  environment {
    variables = {
      env           = var.environment
      INPUT_BUCKET  = aws_s3_bucket.content_input.bucket
      RESULTS_BUCKET = aws_s3_bucket.content_results.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.moderation_results.name
    }
  }

  tags = local.tags
}

########################################
# Video Moderation Lambda
########################################
resource "aws_lambda_function" "video_moderation" {
  function_name = "${local.name_prefix}-video-moderation"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 2048

  filename         = "../services/VideoModeration/VideoModeration.zip"
  source_code_hash = filebase64sha256("../services/VideoModeration/VideoModeration.zip")

  environment {
    variables = {
      env           = var.environment
      INPUT_BUCKET  = aws_s3_bucket.content_input.bucket
      RESULTS_BUCKET = aws_s3_bucket.content_results.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.moderation_results.name
    }
  }

  tags = local.tags
}

########################################
# Decision Engine Lambda
########################################
resource "aws_lambda_function" "decision_engine" {
  function_name = "${local.name_prefix}-decision-engine"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  filename         = "../services/DecisionEngine/DecisionEngine.zip"
  source_code_hash = filebase64sha256("../services/DecisionEngine/DecisionEngine.zip")

  environment {
    variables = {
      env           = var.environment
      RESULTS_BUCKET = aws_s3_bucket.content_results.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.moderation_results.name
    }
  }

  tags = local.tags
}

########################################
# Ingestion Lambda
########################################
resource "aws_lambda_function" "ingestion_lambda" {
  function_name = "${local.name_prefix}-ingestion-lambda"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  filename         = "../services/Ingestion/Ingestion.zip"
  source_code_hash = filebase64sha256("../services/Ingestion/Ingestion.zip")

  environment {
    variables = {
      STEP_FUNCTION_ARN = aws_sfn_state_machine.moderation_pipeline.arn
    }
  }

  tags = local.tags
}
