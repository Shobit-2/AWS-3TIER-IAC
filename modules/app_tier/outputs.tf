output "internal_alb_dns_name" {
  description = "DNS name of the internal load balancer"
  value       = aws_lb.internal.dns_name
}

output "internal_alb_arn" {
  description = "ARN of the internal load balancer"
  value       = aws_lb.internal.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app_tier.arn
}
