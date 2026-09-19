# ---------------------------------------------------------
# Dead Letter Queue
# ---------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  name = var.dlq_name

  message_retention_seconds = var.message_retention_seconds

  tags = {
    Name        = var.dlq_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# ---------------------------------------------------------
# Main Order Queue
# ---------------------------------------------------------

resource "aws_sqs_queue" "main" {
  name = var.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name        = var.queue_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
