variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_dir" {
  description = "Directory containing Lambda source code"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 256
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS order queue"
  type        = string
}
