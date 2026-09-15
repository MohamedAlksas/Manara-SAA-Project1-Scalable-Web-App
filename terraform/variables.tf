variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.10.0/24"
    "us-east-1b" = "10.0.20.0/24"
  }
}

variable "private_app_subnets" {
  description = "CIDR blocks for private application subnets"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.100.0/24"
    "us-east-1b" = "10.0.200.0/24"
  }
}

variable "private_db_subnets" {
  description = "CIDR blocks for private database subnets"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.201.0/24"
    "us-east-1b" = "10.0.202.0/24"
  }
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Database instance class for Amazon RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for RDS (Min 8 characters)"
  type        = string
  default     = "P@ssw0rdSecure2026"
  sensitive   = true
}

variable "domain_name" {
  description = "Route 53 hosted zone domain name (optional)"
  type        = string
  default     = "example.com"
}

variable "alert_email" {
  description = "Admin email address for CloudWatch / SNS alarms"
  type        = string
  default     = "admin@example.com"
}
