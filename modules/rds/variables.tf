variable "db_identifier" {
  description = "RDS cluster identifier"
  type        = string
}

variable "db_subnet_group_name" {
  description = "RDS subnet group name"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Database security group ID"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
}
