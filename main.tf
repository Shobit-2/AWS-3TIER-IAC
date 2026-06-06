terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  aws_region           = var.aws_region
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_app_cidrs    = var.private_app_cidrs
  private_db_cidrs     = var.private_db_cidrs
  environment          = var.environment
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  s3_bucket_name = var.s3_bucket_name
  environment    = var.environment
}

# Database Module
module "rds" {
  source = "./modules/rds"

  db_identifier              = "${var.environment}-webappdb"
  db_subnet_group_name       = "${var.environment}-db-subnet-group"
  private_db_subnet_ids      = module.vpc.private_db_subnet_ids
  database_security_group_id = module.security_groups.db_security_group_id
  db_username                = var.db_username
  db_password                = var.db_password
  environment                = var.environment

  depends_on = [module.security_groups]
}

# App Tier Module
module "app_tier" {
  source = "./modules/app_tier"

  instance_type              = var.app_instance_type
  private_app_subnet_ids     = module.vpc.private_app_subnet_ids
  app_security_group_id      = module.security_groups.app_security_group_id
  iam_instance_profile       = module.iam.ec2_instance_profile_name
  s3_bucket_name             = var.s3_bucket_name
  ami_id                     = data.aws_ami.amazon_linux_2.id
  db_endpoint                = module.rds.db_endpoint
  db_username                = var.db_username
  db_password                = var.db_password
  environment                = var.environment
  availability_zones         = var.availability_zones

  depends_on = [module.security_groups, module.rds]
}

# Web Tier Module
module "web_tier" {
  source = "./modules/web_tier"

  instance_type               = var.web_instance_type
  public_subnet_ids           = module.vpc.public_subnet_ids
  web_security_group_id       = module.security_groups.web_security_group_id
  iam_instance_profile        = module.iam.ec2_instance_profile_name
  s3_bucket_name              = var.s3_bucket_name
  ami_id                      = data.aws_ami.amazon_linux_2.id
  internal_alb_dns            = module.app_tier.internal_alb_dns_name
  environment                 = var.environment
  availability_zones          = var.availability_zones

  depends_on = [module.security_groups, module.app_tier]
}

# Outputs
output "external_alb_dns_name" {
  description = "DNS name of the external load balancer"
  value       = module.web_tier.external_alb_dns_name
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name for application code"
  value       = var.s3_bucket_name
}
