output "vpc_id" {
  value = aws_vpc.ThreeTierAppVPC.id
}

output "publicsubnet1_id" {
  value = aws_subnet.PublicSubnet1.id
}

output "publicsubnet2_id" {
  value = aws_subnet.PublicSubnet2.id
}