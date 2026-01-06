# Upload API Lambda
resource "aws_lambda_function" "upload_api" {
  function_name = "${local.name_prefix}-upload-api"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = "python3.11"
  handler       = "handler.handler"
  filename      = "../services/UploadApi/UploadApi.zip"
  memory_size   = 256
  timeout       = 10
  environment {
    variables = {
      UPLOAD_BUCKET  = aws_s3_bucket.content_input.bucket
      URL_EXPIRATION = "300"
    }
  }
  tags = local.tags
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "content_upload_api" {
  name = "${local.name_prefix}-upload-api"
}

resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.content_upload_api.id
  parent_id   = aws_api_gateway_rest_api.content_upload_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.content_upload_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_lambda" {
  rest_api_id = aws_api_gateway_rest_api.content_upload_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_api.invoke_arn
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.content_upload_api.execution_arn}/*/*"
}
