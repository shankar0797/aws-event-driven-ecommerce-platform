variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "container_name" {
  description = "Name of the application container"
  type        = string
}

variable "container_image" {
  description = "Docker image URI from ECR"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
}

variable "cpu" {
  description = "CPU units for the ECS task"
  type        = number
}

variable "memory" {
  description = "Memory in MB for the ECS task"
  type        = number
}

variable "desired_count" {
  description = "Number of ECS tasks that should run"
  type        = number
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID assigned to ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
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
variable "sqs_queue_arn" {
  description = "ARN of the SQS order queue"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS order queue"
  type        = string
}


variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks for auto scaling"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks for auto scaling"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target average CPU utilization percentage"
  type        = number
  default     = 60
}


