###############################################################################################################################

################################################
#Frontend
################################################

# Create the user data scripts using templatefile function
locals {
  frontend_user_data = templatefile("${path.module}/templates/frontend.sh.tpl", {})
  backend_user_data  = templatefile("${path.module}/templates/backend.sh.tpl", {})
}

module "Frontend" {
  source               = "git::https://github.com/selelyriq/TF-EC2.git?ref=02299c74c3cb5610580b08de9579b82ba3b436c5"
  instance_type        = var.instance_type
  ami_id               = var.frontend_ami_id
  subnet_id            = aws_subnet.PublicSubnet.id
  name                 = var.frontend_name
  user_data            = local.frontend_user_data
  tags                 = var.frontend_tags
  security_group_id    = aws_security_group.FrontendSG.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_vpc" "ThreeTierAppVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ThreeTierAppVPC"
  }
}

resource "aws_subnet" "PublicSubnet" {
  vpc_id     = aws_vpc.ThreeTierAppVPC.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.ThreeTierAppVPC.id
  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.ThreeTierAppVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table_association" "PublicRTAssociation" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_security_group" "FrontendSG" {
  name        = "FrontendSG"
  description = var.frontend_sg_description
  vpc_id      = aws_vpc.ThreeTierAppVPC.id
}

resource "aws_security_group_rule" "FrontendSGIngress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.FrontendSG.id
}

resource "aws_security_group_rule" "FrontendSGIngressHTTPS" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.FrontendSG.id
  description       = var.frontend_https_description
}

# Frontend egress - needs internet access for updates and responses
resource "aws_security_group_rule" "FrontendSGEgress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.FrontendSG.id
  description       = "Allow HTTPS outbound traffic for updates and responses"
}

###############################################################################################################################

################################################
#Backend
################################################

module "Backend" {
  source               = "git::https://github.com/selelyriq/TF-EC2.git?ref=02299c74c3cb5610580b08de9579b82ba3b436c5"
  instance_type        = var.instance_type
  ami_id               = var.backend_ami_id
  subnet_id            = aws_subnet.PrivateSubnet.id
  name                 = var.backend_name
  user_data            = local.backend_user_data
  tags                 = var.backend_tags
  security_group_id    = aws_security_group.BackendSG.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id     = aws_vpc.ThreeTierAppVPC.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "NAT Gateway EIP"
  }

  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_nat_gateway" "NAT" {
  subnet_id     = aws_subnet.PublicSubnet.id
  allocation_id = aws_eip.nat_eip.id

  # Add explicit dependency on the Internet Gateway
  depends_on = [aws_internet_gateway.IGW]

  tags = {
    Name = "NAT"
  }
}

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.ThreeTierAppVPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT.id
  }
}

resource "aws_route_table_association" "PrivateRTAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_security_group" "BackendSG" {
  name        = "BackendSG"
  description = var.backend_sg_description
  vpc_id      = aws_vpc.ThreeTierAppVPC.id
}

resource "aws_security_group_rule" "BackendSGIngress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.FrontendSG.id
  security_group_id        = aws_security_group.BackendSG.id
}

# Backend egress - only needs to talk to the database
resource "aws_security_group_rule" "BackendSGEgress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.DatabaseSG.id
  security_group_id        = aws_security_group.BackendSG.id
  description              = "Allow MySQL traffic to database tier"
}

###############################################################################################################################

################################################
#Database
################################################

module "Database" {
  source                    = "git::https://github.com/selelyriq/TF-RDS.git?ref=b9de02b5ba3dbab58507a473e550ca6ad6ac4344"
  identifier                = var.identifier
  engine                    = var.engine
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  username                  = var.username
  tags                      = var.database_tags
  skip_final_snapshot       = true
  final_snapshot_identifier = "three-tier-app-final-snapshot" # Provide a valid name even though we're skipping
  snapshot_identifier       = null
}

resource "aws_security_group" "DatabaseSG" {
  name        = "DatabaseSG"
  description = var.database_sg_description
  vpc_id      = aws_vpc.ThreeTierAppVPC.id
}

resource "aws_security_group_rule" "DatabaseSGIngress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.BackendSG.id
  security_group_id        = aws_security_group.DatabaseSG.id
}

# Database egress - only needs to respond to backend
resource "aws_security_group_rule" "DatabaseSGEgress" {
  type                     = "egress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.BackendSG.id
  security_group_id        = aws_security_group.DatabaseSG.id
  description              = "Allow response traffic to backend tier"
}

# Create KMS key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_log_key" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add KMS key alias
resource "aws_kms_alias" "cloudwatch_log_key_alias" {
  name          = "alias/cloudwatch-log-key"
  target_key_id = aws_kms_key.cloudwatch_log_key.key_id
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Update CloudWatch Log Group to use KMS encryption
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.ThreeTierAppVPC.id}"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_log_key.arn
}

# Create IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

# Enable VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = var.flow_logs_traffic_type
  vpc_id          = aws_vpc.ThreeTierAppVPC.id
}

# Create IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2_discovery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Update IAM policy for EC2 to include both discovery and CloudWatch permissions
resource "aws_iam_role_policy" "ec2_discovery_policy" {
  name = "ec2_discovery_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "rds:DescribeDBInstances",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add CloudWatch Agent policy attachment to the existing EC2 role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_discovery_profile"
  role = aws_iam_role.ec2_role.name
}

################################################
#Monitoring
################################################

# Create CloudWatch Log Group for Cost Allocation Tags
resource "aws_cloudwatch_log_group" "cost_allocation_tag_log_group" {
  name              = "/custom/three-tier-app/cost-allocation"
  retention_in_days = var.retention_in_days
  tags              = var.cloudwatch_tags
}

# Create CloudWatch Metric Filter for Cost Allocation Tags
resource "aws_cloudwatch_log_metric_filter" "cost_allocation_tag_filter" {
  name           = var.name
  pattern        = var.pattern
  log_group_name = aws_cloudwatch_log_group.cost_allocation_tag_log_group.name

  metric_transformation {
    name      = var.metric_name
    namespace = "Custom/ThreeTierApp"
    value     = "1"
  }

  depends_on = [aws_cloudwatch_log_group.cost_allocation_tag_log_group]
}

# Create CloudWatch Alarm for Cost Allocation Tags
resource "aws_cloudwatch_metric_alarm" "cost_allocation_tag_alarm" {
  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  statistic           = var.statistic
  metric_name         = var.metric_name
  namespace           = "Custom/ThreeTierApp"
  period              = 300 # 5 minutes in seconds
}

################################################
#Dashboard
################################################

resource "aws_cloudwatch_dashboard" "three_tier_app_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              "var.frontend_instance_id"
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Frontend Instance Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              "var.backend_instance_id"
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Backend Instance Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              "var.identifier"
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Database Instance Metrics"
        }
      }
    ]
  })
}










