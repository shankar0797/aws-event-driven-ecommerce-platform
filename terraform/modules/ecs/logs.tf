# ---------------------------------------------------------
# CloudWatch Log Group for ECS
# ---------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = 7

  tags = {
    Name        = var.log_group_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

