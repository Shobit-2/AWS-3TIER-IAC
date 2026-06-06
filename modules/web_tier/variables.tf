variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Web tier security group ID"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for application code"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "internal_alb_dns" {
  description = "Internal load balancer DNS name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
