variable "instance_type" {
  type = string
}

variable "frontend_name" {
  type = string
}

variable "backend_name" {
  type = string
}

variable "identifier" {
  type = string
}

variable "engine" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "username" {
  type = string
}

variable "frontend_tags" {
  type = map(string)
}

variable "backend_tags" {
  type = map(string)
}

variable "frontend_ami_id" {
  type = string
}

variable "backend_ami_id" {
  type = string
}

variable "database_tags" {
  type = map(string)
}

variable "allocated_storage" {
  type = number
}

variable "frontend_sg_description" {
  type        = string
  description = "Description for the frontend security group"
  default     = "Security group for frontend web servers - allows inbound HTTP/HTTPS traffic from internet"
}

variable "backend_sg_description" {
  type        = string
  description = "Description for the backend security group"
  default     = "Security group for backend application servers - allows inbound HTTP traffic from frontend only"
}

variable "database_sg_description" {
  type        = string
  description = "Description for the database security group"
  default     = "Security group for RDS database - allows inbound MySQL traffic from backend servers only"
}

variable "flow_logs_retention_days" {
  type        = number
  description = "Number of days to retain VPC Flow Logs in CloudWatch"
  default     = 30
}

variable "flow_logs_traffic_type" {
  type        = string
  description = "Type of traffic to log. Valid values: ACCEPT, REJECT, ALL"
  default     = "ALL"
}

variable "frontend_https_description" {
  type        = string
  description = "Description for the frontend HTTPS ingress rule"
  default     = "Allow inbound HTTPS traffic from internet"
}

variable "kms_deletion_window" {
  type        = number
  description = "Duration in days after which the KMS key is deleted after destruction of the resource"
  default     = 7
}

# variable "frontend_user_data" {
#   type        = string
#   description = "User data script for frontend instance"
#   default     = <<EOF
# #!/bin/bash
# # Install nginx for serving static content
# apt-get update
# apt-get install -y nginx

# # Wait for instance metadata service to be available
# while ! curl -s http://169.254.169.254/latest/meta-data/; do
#     sleep 1
# done

# # Get the backend instance private IP using AWS CLI
# apt-get install -y awscli
# BACKEND_IP=$(aws ec2 describe-instances \
#     --filters "Name=tag:Name,Values=Backend" \
#               "Name=instance-state-name,Values=running" \
#     --query 'Reservations[*].Instances[*].PrivateIpAddress' \
#     --output text \
#     --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region))

# # Create a simple HTML page that will make API calls to backend
# cat <<HTMLFILE > /var/www/html/index.html
# <!DOCTYPE html>
# <html>
# <head>
#     <title>Three Tier App</title>
# </head>
# <body>
#     <h1>Welcome to Our Application</h1>
#     <div id="result"></div>
#     <script>
#         const backendUrl = 'http://${BACKEND_IP}/api/data';
#         fetch(backendUrl)
#             .then(response => response.json())
#             .then(data => {
#                 document.getElementById('result').innerHTML = JSON.stringify(data);
#             })
#             .catch(error => {
#                 document.getElementById('result').innerHTML = 'Error: ' + error.message;
#             });
#     </script>
# </body>
# </html>
# HTMLFILE

# systemctl enable nginx
# systemctl start nginx
# EOF
# }

# variable "backend_user_data" {
#   type        = string
#   description = "User data script for backend instance"
#   default     = <<EOF
# #!/bin/bash
# # Install Node.js and npm
# apt-get update
# apt-get install -y nodejs npm awscli

# # Get the RDS endpoint using AWS CLI
# DB_ENDPOINT=$(aws rds describe-db-instances \
#     --db-instance-identifier "three-tier-app" \
#     --query 'DBInstances[0].Endpoint.Address' \
#     --output text \
#     --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region))

# # Create a directory for our application
# mkdir -p /app
# cd /app

# # Initialize a new Node.js application
# npm init -y

# # Install Express.js and MySQL client
# npm install express mysql2

# # Create the backend API server
# cat <<NODEFILE > /app/server.js
# const express = require('express');
# const mysql = require('mysql2');
# const app = express();

# const db = mysql.createConnection({
#     host: '${DB_ENDPOINT}',
#     user: 'admin',
#     password: process.env.DB_PASSWORD,
#     database: 'appdb'
# });

# app.use(express.json());

# // Enable CORS for frontend
# app.use((req, res, next) => {
#     res.header('Access-Control-Allow-Origin', '*');
#     res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
#     next();
# });

# // Sample API endpoint
# app.get('/api/data', async (req, res) => {
#     db.query('SELECT * FROM sample_table', (err, results) => {
#         if (err) {
#             res.status(500).json({ error: err.message });
#             return;
#         }
#         res.json(results);
#     });
# });

# app.listen(80, () => {
#     console.log('Backend server running on port 80');
# });
# NODEFILE

# # Create a systemd service for the Node.js application
# cat <<'SERVICEFILE' > /etc/systemd/system/backend.service
# [Unit]
# Description=Backend Node.js Application
# After=network.target

# [Service]
# Type=simple
# User=root
# WorkingDirectory=/app
# ExecStart=/usr/bin/node server.js
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target
# SERVICEFILE

# # Start the backend service
# systemctl enable backend
# systemctl start backend
# EOF
# }

variable "db_init_script" {
  type        = string
  description = "Initial SQL script to create database schema"
  default     = <<EOF
CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;
CREATE TABLE IF NOT EXISTS sample_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO sample_table (name) VALUES ('Sample Data 1'), ('Sample Data 2');
EOF
}

variable "snapshot_identifier" {
  type        = string
  description = "The name of the snapshot to create before destroying the RDS instance"
  default     = null # or a specific name if you want to use snapshots
}

variable "final_snapshot_identifier" {
  type        = string
  description = "The name of the final snapshot when destroying the RDS instance"
  default     = null # This is fine since we're skipping final snapshots
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to skip the final snapshot when destroying the RDS instance"
  default     = true
}
