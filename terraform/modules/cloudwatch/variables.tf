variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "alb_target_group_arn_suffix" {
  description = "ALB target group ARN suffix used by CloudWatch"
  type        = string
}

variable "alb_load_balancer_arn_suffix" {
  description = "ALB load balancer ARN suffix used by CloudWatch"
  type        = string
}

variable "sqs_queue_name" {
  description = "SQS queue name"
  type        = string
}
