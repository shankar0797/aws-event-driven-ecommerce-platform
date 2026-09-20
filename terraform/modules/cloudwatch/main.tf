# ---------------------------------------------------------
# ECS CPU Alarm
# ---------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  alarm_description   = "ECS service average CPU utilization is above 80%"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  period             = 60
  threshold          = 80

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project_name}-ecs-cpu-high"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------
# ALB HTTP 5XX Alarm
# ---------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx"
  alarm_description   = "ALB is returning HTTP 5XX responses"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 2
  period             = 60
  threshold          = 5

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  statistic   = "Sum"

  dimensions = {
    TargetGroup  = var.alb_target_group_arn_suffix
    LoadBalancer = var.alb_load_balancer_arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project_name}-alb-5xx"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------
# SQS Backlog Alarm
# ---------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "sqs_backlog" {
  alarm_name          = "${var.project_name}-sqs-backlog"
  alarm_description   = "SQS order queue has a backlog of messages"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 2
  period             = 60
  threshold          = 10

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Average"

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project_name}-sqs-backlog"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
