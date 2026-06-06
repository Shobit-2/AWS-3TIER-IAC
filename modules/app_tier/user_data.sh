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

# Install PM2 globally
npm install -g pm2

# Install MySQL CLI
yum install mysql -y

# Download application code from S3
cd /home/ec2-user
aws s3 cp s3://${s3_bucket}/app-tier/ app-tier --recursive

# Create DbConfig.js with database credentials
cat > /home/ec2-user/app-tier/DbConfig.js << 'EOF'
const mysql = require('mysql');

const pool = mysql.createPool({
  connectionLimit: 10,
  host: '${db_endpoint}',
  user: '${db_username}',
  password: '${db_password}',
  database: 'webappdb'
});

module.exports = pool;
EOF

# Install dependencies
cd /home/ec2-user/app-tier
npm install

# Start application with PM2
pm2 start index.js
pm2 startup
pm2 save

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user
