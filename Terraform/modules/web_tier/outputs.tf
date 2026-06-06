output "external_alb_dns_name" {
  description = "DNS name of the external load balancer"
  value       = aws_lb.external.dns_name
}

output "external_alb_arn" {
  description = "ARN of the external load balancer"
  value       = aws_lb.external.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web_tier.arn
}
