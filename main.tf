###############################################################################################################################

################################################
#Frontend
################################################

module "Frontend" {
  source            = "git::https://github.com/selelyriq/TF-EC2.git?ref=b9a04d59deb2f6085ed684bcdabb9ee35aa16987"
  instance_type     = var.instance_type
  ami_id            = var.frontend_ami_id
  subnet_id         = aws_subnet.PublicSubnet.id
  name              = var.frontend_name
  user_data         = var.user_data
  tags              = var.frontend_tags
  security_group_id = aws_security_group.FrontendSG.id
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
  source            = "git::https://github.com/selelyriq/TF-EC2.git?ref=b9a04d59deb2f6085ed684bcdabb9ee35aa16987"
  instance_type     = var.instance_type
  ami_id            = var.backend_ami_id
  subnet_id         = aws_subnet.PrivateSubnet.id
  name              = var.backend_name
  user_data         = var.user_data
  tags              = var.backend_tags
  security_group_id = aws_security_group.BackendSG.id
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id     = aws_vpc.ThreeTierAppVPC.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_nat_gateway" "NAT" {
  subnet_id = aws_subnet.PublicSubnet.id
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
  source            = "git::https://github.com/selelyriq/TF-RDS.git?ref=dd5e96928d53949fe58d7e1d3bf7999fc38fbfbe"
  identifier        = var.identifier
  engine            = var.engine
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  username          = var.username
  tags              = var.database_tags
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




