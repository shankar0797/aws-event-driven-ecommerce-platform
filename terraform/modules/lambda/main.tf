data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/process_order.zip"
}


resource "aws_lambda_function" "this" {
  function_name = var.function_name

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = var.runtime
  handler = var.handler

  role = aws_iam_role.lambda.arn

  timeout     = var.timeout
  memory_size = var.memory_size

  tags = {
    Name        = var.function_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.arn

  batch_size                         = 1
  function_response_types            = ["ReportBatchItemFailures"]
  enabled                            = true
}

