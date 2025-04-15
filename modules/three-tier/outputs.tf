output "frontend_public_ip" {
  value = module.Frontend.ec2_instance_public_ip
}

output "backend_instance_id" {
  value = module.Backend.ec2_instance_id
}

output "frontend_instance_id" {
  value = module.Frontend.ec2_instance_id
}

output "vpc_id" {
  value = aws_vpc.ThreeTierAppVPC.id
}

output "vpc_arn" {
  value = aws_vpc.ThreeTierAppVPC.arn
}

output "publicsubnet1_id" {
  value = aws_subnet.PublicSubnet1.id
}

output "publicsubnet1_arn" {
  value = aws_subnet.PublicSubnet1.arn
}

output "publicsubnet2_id" {
  value = aws_subnet.PublicSubnet2.id
}

output "publicsubnet2_arn" {
  value = aws_subnet.PublicSubnet2.arn
}