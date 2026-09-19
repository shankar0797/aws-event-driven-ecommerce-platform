variable "queue_name" {
  description = "Name of the main SQS queue"
  type        = string
}

variable "dlq_name" {
  description = "Name of the SQS dead-letter queue"
  type        = string
}

variable "max_receive_count" {
  description = "Number of receives before a message moves to the DLQ"
  type        = number
  default     = 3
}

variable "visibility_timeout_seconds" {
  description = "How long a received message remains invisible"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "How long messages are retained"
  type        = number
  default     = 345600
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
