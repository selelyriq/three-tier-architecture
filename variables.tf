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

variable "user_data" {
  type    = string
  default = <<EOF
echo "Hello, World!" > /var/www/html/index.html
EOF
}
