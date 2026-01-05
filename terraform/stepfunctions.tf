resource "aws_sfn_state_machine" "moderation_pipeline" {
  name     = "${local.name_prefix}-moderation-pipeline"  # kebab-case
  role_arn = aws_iam_role.step_functions_execution.arn

  definition = jsonencode({
    Comment = "Optimal Content Moderation Pipeline"
    StartAt = "CheckContentType"
    States = {

      # Choice State for content type routing
      CheckContentType = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.contentType"
            StringEquals = "text"
            Next = "TextModerationTaskSingle"
          },
          {
            Variable = "$.contentType"
            StringEquals = "image"
            Next = "ImageModerationTaskSingle"
          },
          {
            Variable = "$.contentType"
            StringEquals = "video"
            Next = "VideoModerationTaskSingle"
          }
        ]
        Default = "ParallelModeration"
      },

      # Single-task paths for direct content type
      TextModerationTaskSingle = {
        Type = "Task"
        Resource = aws_lambda_function.text_moderation.arn
        Next = "DecisionEngineTask"
        Retry = [{
          ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts = 2
          BackoffRate = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "Failure"
        }]
      },

      ImageModerationTaskSingle = {
        Type = "Task"
        Resource = aws_lambda_function.image_moderation.arn
        Next = "DecisionEngineTask"
        Retry = [{
          ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts = 2
          BackoffRate = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "Failure"
        }]
      },

      VideoModerationTaskSingle = {
        Type = "Task"
        Resource = aws_lambda_function.video_moderation.arn
        Next = "DecisionEngineTask"
        Retry = [{
          ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts = 2
          BackoffRate = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "Failure"
        }]
      },

      # Parallel moderation for mixed content
      ParallelModeration = {
        Type = "Parallel"
        Branches = [

          # Text moderation branch
          {
            StartAt = "TextModerationTaskBranch"
            States = {
              TextModerationTaskBranch = {
                Type = "Task"
                Resource = aws_lambda_function.text_moderation.arn
                End = true
                Retry = [{
                  ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
                  IntervalSeconds = 2
                  MaxAttempts = 2
                  BackoffRate = 2
                }]
                Catch = [{
                  ErrorEquals = ["States.ALL"]
                  Next = "TextModerationFailure"
                }]
              }
              TextModerationFailure = {
                Type = "Fail"
                Cause = "Text moderation failed"
                Error = "TextModerationError"
              }
            }
          },

          # Image moderation branch
          {
            StartAt = "ImageModerationTaskBranch"
            States = {
              ImageModerationTaskBranch = {
                Type = "Task"
                Resource = aws_lambda_function.image_moderation.arn
                End = true
                Retry = [{
                  ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
                  IntervalSeconds = 2
                  MaxAttempts = 2
                  BackoffRate = 2
                }]
                Catch = [{
                  ErrorEquals = ["States.ALL"]
                  Next = "ImageModerationFailure"
                }]
              }
              ImageModerationFailure = {
                Type = "Fail"
                Cause = "Image moderation failed"
                Error = "ImageModerationError"
              }
            }
          },

          # Video moderation branch
          {
            StartAt = "VideoModerationTaskBranch"
            States = {
              VideoModerationTaskBranch = {
                Type = "Task"
                Resource = aws_lambda_function.video_moderation.arn
                End = true
                Retry = [{
                  ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
                  IntervalSeconds = 2
                  MaxAttempts = 2
                  BackoffRate = 2
                }]
                Catch = [{
                  ErrorEquals = ["States.ALL"]
                  Next = "VideoModerationFailure"
                }]
              }
              VideoModerationFailure = {
                Type = "Fail"
                Cause = "Video moderation failed"
                Error = "VideoModerationError"
              }
            }
          }

        ]
        Next = "DecisionEngineTask"
      },

      # Decision Engine Lambda
      DecisionEngineTask = {
        Type = "Task"
        Resource = aws_lambda_function.decision_engine.arn
        End = true
        Retry = [{
          ErrorEquals = ["Lambda.ServiceException","Lambda.AWSLambdaException","Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts = 2
          BackoffRate = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "Failure"
        }]
      },

      # Global Failure State
      Failure = {
        Type = "Fail"
        Cause = "Moderation pipeline failed"
        Error = "ModerationPipelineError"
      }
    }
  })

  tags = local.tags
}
