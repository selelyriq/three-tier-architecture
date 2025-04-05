output "frontend_public_ip" {
  value = module.Frontend.ec2_instance_public_ip
}

# output "backend_instance_id" {
#   value = module.Backend.ec2_instance_id
# }

# output "frontend_instance_id" {
#   value = module.Frontend.ec2_instance_id
# } 