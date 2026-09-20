output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.this.arn
}
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

