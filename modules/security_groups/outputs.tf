output "external_alb_security_group_id" {
  description = "ID of the external ALB security group"
  value       = aws_security_group.external_alb.id
}

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web_tier.id
}

output "internal_alb_security_group_id" {
  description = "ID of the internal ALB security group"
  value       = aws_security_group.internal_alb.id
}

output "app_security_group_id" {
  description = "ID of the app tier security group"
  value       = aws_security_group.app_tier.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
