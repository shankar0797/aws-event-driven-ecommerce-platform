resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.function_name}-execution-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.lambda.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy" "sqs_consumer" {
  name = "${var.function_name}-sqs-consumer-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = var.sqs_queue_arn
      }
    ]
  })
}
