################################################
#Common Variables
################################################

instance_type = "t2.micro"
engine        = "mysql"
username      = "admin"

################################################
#Frontend Configuration
################################################

frontend_name = "Frontend"
frontend_ami_ids = {
  "us-east-1" = "ami-07f63a768d21af353"
  "us-east-2" = "ami-0dc4d63a667057757" # Replace with actual us-east-2 AMI
}
frontend_tags = {
  Name        = "Frontend"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Backend Configuration
################################################

backend_name = "Backend"
backend_ami_ids = {
  "us-east-1" = "ami-07f63a768d21af353"
  "us-east-2" = "ami-0dc4d63a667057757" # Replace with actual us-east-2 AMI
}
backend_tags = {
  Name        = "Backend"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Database Configuration
################################################

identifier        = "three-tier-app"
instance_class    = "db.t3.micro"
allocated_storage = 20
database_tags = {
  Name        = "Database"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Security Groups
################################################

frontend_sg_description = "Allow inbound HTTP/HTTPS traffic from internet"
backend_sg_description  = "Allow inbound HTTP traffic from frontend only"
database_sg_description = "Allow inbound MySQL traffic from backend servers only"

################################################
#CloudWatch Configuration
################################################

name                = "cost-allocation-filter"
pattern             = "[timestamp, requestid, field3, field4, cost=*]"
metric_name         = "CostAllocationTag"
namespace           = "ThreeTierApp/Metrics"
value               = "$.cost"
alarm_name          = "CostAllocationTagAlarm"
comparison_operator = "GreaterThanThreshold"
evaluation_periods  = 1
threshold           = 10
statistic           = "Sum"
period              = 300
retention_in_days   = 30
log_group_name      = "/custom/three-tier-app/cost-allocation"
cloudwatch_tags = {
  Name        = "CloudWatch"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Dashboard Configuration
################################################

dashboard_name = "ThreeTierAppDashboard"