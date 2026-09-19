# ---------------------------------------------------------
# Main Queue Outputs
# ---------------------------------------------------------

output "queue_url" {
  description = "URL of the main SQS order queue"
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN of the main SQS order queue"
  value       = aws_sqs_queue.main.arn
}


# ---------------------------------------------------------
# Dead Letter Queue Outputs
# ---------------------------------------------------------

output "dlq_url" {
  description = "URL of the SQS dead-letter queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the SQS dead-letter queue"
  value       = aws_sqs_queue.dlq.arn
}
