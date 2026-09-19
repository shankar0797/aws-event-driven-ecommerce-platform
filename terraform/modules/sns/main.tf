resource "aws_sns_topic" "this" {
  name = var.topic_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

