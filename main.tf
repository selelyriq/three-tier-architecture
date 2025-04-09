module "three_tier" {
  source = "./modules/three-tier"
  providers = {
    aws = aws.us_east_1
  }

  # Pass all existing variables
  instance_type       = var.instance_type
  frontend_ami_id     = var.frontend_ami_ids["us-east-1"]
  backend_ami_id      = var.backend_ami_ids["us-east-1"]
  frontend_name       = "${var.frontend_name}-us-east-1"
  backend_name        = "${var.backend_name}-us-east-1"
  identifier          = "${var.identifier}-us-east-1"
  engine              = var.engine
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  username            = var.username
  frontend_tags       = var.frontend_tags
  backend_tags        = var.backend_tags
  database_tags       = var.database_tags
  name                = "${var.name}-us-east-1"
  pattern             = var.pattern
  metric_name         = var.metric_name
  value               = var.value
  alarm_name          = "${var.alarm_name}-us-east-1"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  statistic           = var.statistic
  log_group_name      = "${var.log_group_name}-us-east-1"
  retention_in_days   = var.retention_in_days
  cloudwatch_tags     = var.cloudwatch_tags
  dashboard_name      = "${var.dashboard_name}-us-east-1"
}

# resource "aws_launch_template" "three_tier_launch_template" {
#   name = "${var.name}-us-east-1"
#   image_id = var.frontend_ami_ids["us-east-1"]
#   instance_type = var.instance_type
#   user_data = base64encode(templatefile("${path.module}/user-data.sh", {
#     frontend_ami_id = var.frontend_ami_ids["us-east-1"]
#     backend_ami_id = var.backend_ami_ids["us-east-1"]
#   }))
# }

resource "aws_organizations_policy" "scp-ec2-instance-type" {
  name        = "scp-ec2-instance-type"
  description = "SCP for three-tier"
  content     = data.aws_iam_policy_document.scp-ec2-instance-type.json
}

resource "aws_organizations_policy_attachment" "scp-ec2-instance-type-attachment" {
  policy_id = aws_organizations_policy.scp-ec2-instance-type.id
  target_id = "o-zsopj63lcq" # Replace with your organization root ID, OU ID, or account ID
}

resource "aws_organizations_policy" "prevent_vpc_deletion" {
  name        = "prevent-vpc-deletion"
  description = "SCP that prevents deletion of any VPC"
  content     = data.aws_iam_policy_document.scp-prevent-vpc-deletion.json
}

resource "aws_organizations_policy_attachment" "prevent_vpc_deletion_attachment" {
  policy_id = aws_organizations_policy.prevent_vpc_deletion.id
  target_id = "o-zsopj63lcq" # Replace with your organization root ID, OU ID, or account ID
}

# # Optional: Route 53 for DNS failover
# resource "aws_route53_health_check" "frontend_health_check" {
#   ip_address        = module.three_tier.frontend_public_ip
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/"
#   failure_threshold = "3"
#   request_interval  = "30"

#   depends_on = [module.three_tier]
# }

#push