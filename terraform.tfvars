################################################
#Frontend
################################################

instance_type   = "t2.micro"
frontend_ami_id = "ami-07f63a768d21af353"
frontend_name   = "Frontend"
frontend_tags = {
  Name        = "Frontend"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Backend
################################################

backend_ami_id = "ami-07f63a768d21af353"
backend_name   = "Backend"
backend_tags = {
  Name        = "Backend"
  Environment = "Production"
  Project     = "ThreeTierApp"
}

################################################
#Database
################################################

identifier        = "three-tier-app"
engine            = "mysql"
instance_class    = "db.t3.micro"
allocated_storage = 20
username          = "admin"
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
#CloudWatch
################################################

name                = "CloudWatch"
pattern             = ""
metric_name         = "CostAllocationTag"
namespace           = "ThreeTierApp/Metrics"
value               = "CostAllocationTag"
alarm_name          = "CostAllocationTagAlarm"
comparison_operator = "GreaterThanThreshold"
evaluation_periods  = 1
threshold           = 10
statistic           = "Sum"
period              = 300
cloudwatch_tags = {
  Name        = "CloudWatch"
  Environment = "Production"
  Project     = "ThreeTierApp"
}