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

variable "name" {
  type = string
}

variable "pattern" {
  type = string
}

variable "metric_name" {
  type = string
}

variable "namespace" {
  description = "The namespace for CloudWatch metrics"
  type        = string
  default     = "Custom/ThreeTierApp"
}

variable "value" {
  type = string
}

variable "alarm_name" {
  type = string
}

variable "comparison_operator" {
  type = string
}

variable "evaluation_periods" {
  type = number
}

variable "threshold" {
  type = number
}

variable "statistic" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "retention_in_days" {
  type = number
}

variable "cloudwatch_tags" {
  type = map(string)
}

variable "period" {
  type        = number
  description = "The period in seconds over which the metric is evaluated"
  default     = 300 # 5 minutes
}