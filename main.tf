module "three_tier_us_east_1" {
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

# Optional: Route 53 for DNS failover
resource "aws_route53_health_check" "frontend_us_east_1" {
  ip_address        = module.three_tier_us_east_1.frontend_public_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
}
