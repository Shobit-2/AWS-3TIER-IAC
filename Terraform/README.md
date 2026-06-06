# AWS 3-Tier Web Application Infrastructure as Code

This repository contains Terraform configuration to deploy a complete 3-tier web application on AWS, based on the architecture from [aws-three-tier-web-app](https://github.com/iamtejasmane/aws-three-tier-web-app).

## Architecture Overview

The deployment creates the following infrastructure:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   External ALB (80)     │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Web Tier (Public)    │
                    │  ┌──────────┬──────────┐ │
                    │  │ Nginx-1  │ Nginx-2  │ │
                    │  └──────────┴──────────┘ │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Internal ALB (4000)    │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    App Tier (Private)   │
                    │  ┌──────────┬──────────┐ │
                    │  │ Node-1   │ Node-2   │ │
                    │  └──────────┴──────────┘ │
                    ���────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Database Tier (RDS)    │
                    │  ┌──────────┬──────────┐ │
                    │  │ Primary  │ Replica  │ │
                    │  └──────────┴──────────┘ │
                    └─────────────────────────┘
```

## Components

### Network Tier
- VPC with custom CIDR block
- Public subnets (Web tier) in 2 AZs
- Private subnets (App tier) in 2 AZs
- Private subnets (Database tier) in 2 AZs
- Internet Gateway for public internet access
- NAT Gateways for private subnet internet access
- Route tables for each tier

### Security
- Security Groups for each tier with minimal required permissions
  - External ALB: HTTP/HTTPS from internet
  - Web tier: HTTP from external ALB
  - Internal ALB: HTTP from web tier
  - App tier: Port 4000 from internal ALB
  - Database: MySQL port 3306 from app tier

### Compute
- EC2 instances in Auto Scaling Groups with launch templates
- Web tier: NGINX web server (2 instances, auto-scaling 2-6)
- App tier: Node.js application (2 instances, auto-scaling 2-6)
- IAM roles with S3 access and Systems Manager permissions

### Load Balancing
- External Application Load Balancer for web tier
- Internal Application Load Balancer for app tier
- Target groups with health checks

### Database
- Amazon Aurora MySQL cluster
- Multi-AZ deployment (primary + replica)
- Automated backups and maintenance windows
- CloudWatch logs integration

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **S3 Bucket** for storing application code (must be created manually)
5. Application code uploaded to S3 with the following structure:
   ```
   s3://your-bucket/
   ├── app-tier/
   │   ├── index.js
   │   ├── DbConfig.js
   │   ├── package.json
   │   └── ...
   ├── web-tier/
   │   ├── src/
   │   ├── public/
   │   ├── package.json
   │   └── ...
   └── nginx.conf
   ```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Shobit-2/AWS-3TIER-IAC.git
cd AWS-3TIER-IAC
```

### 2. Create S3 Bucket for Application Code

```bash
aws s3 mb s3://your-unique-bucket-name --region us-east-1
```

### 3. Prepare Variables

Copy the example variables file and update it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:

```hcl
aws_region     = "us-east-1"
environment     = "prod"
s3_bucket_name = "your-unique-bucket-name"
db_password     = "YourSecurePassword123!"  # Change this!
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

### 6. Apply the Configuration

```bash
terraform apply
```

Confirm the deployment by typing `yes` when prompted.

### 7. Access the Application

After deployment completes, the external load balancer DNS name will be displayed:

```
Outputs:

external_alb_dns_name = "external-alb-1234567890.us-east-1.elb.amazonaws.com"
```

Access the application at: `http://external-alb-1234567890.us-east-1.elb.amazonaws.com`

## Module Structure

```
.
├── main.tf                 # Main configuration with module composition
├── variables.tf            # Root-level variables
├── terraform.tfvars.example # Example values file
└── modules/
    ├── vpc/                # VPC, subnets, internet gateway, NAT gateway
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security_groups/    # Security groups for all tiers
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                # IAM roles and instance profiles
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds/                # Aurora MySQL database cluster
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── app_tier/           # Node.js application tier
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── user_data.sh
    └── web_tier/           # NGINX web tier
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── user_data.sh
```

## Configuration Variables

### Network Configuration
- `vpc_cidr`: VPC CIDR block (default: "10.0.0.0/16")
- `availability_zones`: List of AZs to use (default: ["us-east-1a", "us-east-1b"])
- `public_subnet_cidrs`: Public subnet CIDR blocks
- `private_app_cidrs`: Private app tier subnet CIDR blocks
- `private_db_cidrs`: Private database tier subnet CIDR blocks

### Compute Configuration
- `app_instance_type`: EC2 instance type for app tier (default: "t2.micro")
- `web_instance_type`: EC2 instance type for web tier (default: "t2.micro")

### Database Configuration
- `db_username`: Database master username (default: "admin")
- `db_password`: Database master password (must be changed)

### Application Configuration
- `s3_bucket_name`: S3 bucket containing application code
- `aws_region`: AWS region for deployment
- `environment`: Environment name for resource tagging

## Outputs

- `external_alb_dns_name`: DNS name of the external load balancer
- `rds_endpoint`: RDS database endpoint
- `s3_bucket_name`: S3 bucket name for application code

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

Confirm the destruction by typing `yes` when prompted.

**Note**: The RDS final snapshot will be created during destruction. You can delete it manually from the AWS console if needed.

## Cost Estimation

The default configuration uses AWS free-tier eligible resources:
- **EC2**: t2.micro instances (eligible for free tier)
- **RDS**: db.t3.small instances (not free tier, ~$0.17/hour)
- **ALB**: ~$0.0225/hour
- **NAT Gateway**: ~$0.045/hour per gateway
- **Data Transfer**: Charges apply

**Estimated Monthly Cost**: $100-150 USD (varies by region)

## Customization

### Changing Auto Scaling Parameters

Edit the `desired_capacity`, `min_size`, and `max_size` in:
- `modules/app_tier/main.tf`
- `modules/web_tier/main.tf`

### Using Different Instance Types

Update in `terraform.tfvars`:

```hcl
app_instance_type = "t2.small"
web_instance_type = "t2.small"
```

### Deploying to Different Region

Update in `terraform.tfvars`:

```hcl
aws_region = "us-west-2"
availability_zones = ["us-west-2a", "us-west-2b"]
```

## Security Considerations

1. **Database Password**: Change the default password in `terraform.tfvars`
2. **S3 Bucket**: Enable versioning and encryption on the S3 bucket
3. **Terraform State**: Store `terraform.tfstate` in an S3 backend with encryption
4. **IAM Permissions**: Limit IAM user permissions to necessary services only
5. **HTTPS**: Consider adding HTTPS listener to load balancers
6. **Secrets Management**: Use AWS Secrets Manager for sensitive data

## Troubleshooting

### RDS Connection Issues
1. Verify security group allows port 3306 from app tier
2. Check database endpoint is reachable from app tier
3. Verify database credentials in user data script

### Application Not Accessible
1. Check external ALB security group allows HTTP (port 80)
2. Verify target instances are healthy (check target group health)
3. Check application logs in EC2 instances

### Auto Scaling Not Working
1. Verify IAM instance profile has necessary permissions
2. Check CloudWatch metrics for ASG
3. Review ASG launch template configuration

## References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/)
- [Original 3-Tier Architecture](https://github.com/iamtejasmane/aws-three-tier-web-app)

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and improvements.
