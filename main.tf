###############################################################################################################################

################################################
#Frontend
################################################

module "Frontend" {
  source        = "git::https://github.com/selelyriq/TF-EC2.git?ref=4a0558b9616c6bbbc99ac870a1f0f2929ffe8c7a"
  instance_type = var.instance_type
  ami_id        = var.frontend_ami_id
  subnet_id     = aws_subnet.PublicSubnet.id
  name          = var.frontend_name
  user_data     = var.user_data
  tags          = var.frontend_tags
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
  description = "Security group for the frontend"
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
}

###############################################################################################################################

################################################
#Backend
################################################

module "Backend" {
  source        = "git::https://github.com/selelyriq/TF-EC2.git?ref=4a0558b9616c6bbbc99ac870a1f0f2929ffe8c7a"
  instance_type = var.instance_type
  ami_id        = var.backend_ami_id
  subnet_id     = aws_subnet.PrivateSubnet.id
  name          = var.backend_name
  user_data     = var.user_data
  tags          = var.backend_tags
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
  description = "Security group for the backend"
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

resource "aws_security_group_rule" "BackendSGEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.BackendSG.id
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
  description = "Security group for the database"
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

resource "aws_security_group_rule" "DatabaseSGEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DatabaseSG.id
}




