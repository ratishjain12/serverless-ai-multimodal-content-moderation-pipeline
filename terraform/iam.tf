########################################
# IAM Role and Policies for Lambda Execution
########################################

resource "aws_iam_role" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Base Lambda Permissions (CloudWatch Logs)
resource "aws_iam_policy" "lambda_base" {
  name = "${local.name_prefix}-lambda-base"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_base_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_base.arn
}

# Rekognition Access
resource "aws_iam_policy" "rekognition_access" {
  name = "${local.name_prefix}-rekognition-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectModerationLabels",
          "rekognition:StartContentModeration",
          "rekognition:GetContentModeration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rekognition_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.rekognition_access.arn
}

# Comprehend Access
resource "aws_iam_policy" "comprehend_access" {
  name = "${local.name_prefix}-comprehend-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectToxicContent",
          "comprehend:DetectPiiEntities"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "comprehend_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.comprehend_access.arn
}

# S3 Access for Input and Results
resource "aws_iam_policy" "s3_access" {
  name = "${local.name_prefix}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.content_input.arn,
          "${aws_s3_bucket.content_input.arn}/*",
          aws_s3_bucket.content_results.arn,
          "${aws_s3_bucket.content_results.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# DynamoDB Access for DecisionEngine
resource "aws_iam_policy" "dynamodb_access" {
  name = "${local.name_prefix}-dynamodb-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.moderation_results.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Step Functions Execution Permission for Ingestion Lambda
resource "aws_iam_policy" "step_functions_start_execution" {
  name = "${local.name_prefix}-stepfunctions-start-execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["states:StartExecution"]
        Resource = aws_sfn_state_machine.moderation_pipeline.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.step_functions_start_execution.arn
}

########################################
# Step Functions Execution Role
########################################
resource "aws_iam_role" "step_functions_execution" {
  name = "${local.name_prefix}-step-functions-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# Step Functions invoke Lambda permission
resource "aws_iam_policy" "step_functions_invoke_lambda" {
  name = "${local.name_prefix}-sfn-invoke-lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.ingestion_lambda.arn,
          aws_lambda_function.text_moderation.arn,
          aws_lambda_function.image_moderation.arn,
          aws_lambda_function.video_moderation.arn,
          aws_lambda_function.decision_engine.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_invoke_lambda_attach" {
  role       = aws_iam_role.step_functions_execution.name
  policy_arn = aws_iam_policy.step_functions_invoke_lambda.arn
}
