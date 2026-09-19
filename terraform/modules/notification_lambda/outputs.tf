output "function_name" {
  description = "Notification Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Notification Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "execution_role_arn" {
  description = "Notification Lambda execution role ARN"
  value       = aws_iam_role.lambda.arn
}
