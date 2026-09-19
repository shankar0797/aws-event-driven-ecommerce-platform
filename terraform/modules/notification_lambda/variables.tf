variable "function_name" {
  description = "Notification Lambda function name"
  type        = string
}

variable "source_dir" {
  description = "Notification Lambda source directory"
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
  description = "Lambda timeout"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory"
  type        = number
  default     = 256
}

variable "sns_topic_arn" {
  description = "SNS topic ARN that invokes this Lambda"
  type        = string
}

variable "ses_from_email" {
  description = "Verified SES sender email address"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

