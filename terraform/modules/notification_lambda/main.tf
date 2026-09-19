data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/send_notification.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  filename      = data.archive_file.lambda.output_path

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = var.runtime
  handler = var.handler

  role = aws_iam_role.lambda.arn

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = {
      SES_FROM_EMAIL = var.ses_from_email
    }
  }

  tags = {
    Name        = var.function_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this.arn
}
