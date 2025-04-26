data "aws_ami" "my_ami" {
  most_recent = true
  name_regex = "myami*"
  owners = ["self"]
}

resource "aws_instance" "ec2_instance" {
  ami = data.aws_ami.my_ami.id
  instance_type = "t2.micro"
  key_name = "EC2"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.public_subnet.id
  iam_instance_profile = data.aws_iam_instance_profile.demo_instance_profile.name
}

data "aws_iam_instance_profile" "demo_instance_profile" {
  name = "CloudWatch_SSM"
}
