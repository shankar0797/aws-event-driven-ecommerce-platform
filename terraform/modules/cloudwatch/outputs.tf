output "ecs_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name
}

output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "sqs_backlog_alarm_name" {
  value = aws_cloudwatch_metric_alarm.sqs_backlog.alarm_name
}
