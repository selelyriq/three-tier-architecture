data "aws_ami" "my_ami" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["myami-production-1.0.0-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t2.micro"
  key_name               = "EC2"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_https.id]
  subnet_id              = aws_subnet.public_subnet.id
  iam_instance_profile   = data.aws_iam_instance_profile.demo_instance_profile.name
}

data "aws_iam_instance_profile" "demo_instance_profile" {
  name = "CloudWatch_SSM"
}








resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS access"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}