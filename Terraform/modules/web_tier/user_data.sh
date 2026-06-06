#!/bin/bash
set -e

# Update system
yum update -y

# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js
nvm install 16
nvm use 16

# Install NGINX
amazon-linux-extras install nginx1 -y

# Download web tier code from S3
cd /home/ec2-user
aws s3 cp s3://${s3_bucket}/web-tier/ web-tier --recursive

# Download nginx.conf from S3
cd /etc/nginx
rm -f nginx.conf
aws s3 cp s3://${s3_bucket}/nginx.conf .

# Replace the internal load balancer DNS in nginx.conf
sed -i "s|\[INTERNAL-LOADBALANCER-DNS\]|${internal_alb_dns}|g" /etc/nginx/nginx.conf

# Build React application
cd /home/ec2-user/web-tier
npm install
npm run build

# Fix permissions for NGINX
chmod -R 755 /home/ec2-user

# Start and enable NGINX
systemctl start nginx
systemctl enable nginx

# Fix ownership
chown -R ec2-user:ec2-user /home/ec2-user
