variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "frontend_name" {
  type = string
}

variable "backend_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "identifier" {
  type = string
}

variable "engine" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "username" {
  type = string
}

variable "frontend_tags" {
  type = map(string)
}

variable "backend_tags" {
  type = map(string)
}

variable "user_data" {
  type = string
}

variable "frontend_ami_id" {
  type = string
}

variable "backend_ami_id" {
  type = string
}

variable "database_tags" {
  type = map(string)
}

variable "allocated_storage" {
  type = number
}
