# RDS Subnet Group (Private Database Subnets across 2 AZs)
resource "aws_db_subnet_group" "main" {
  name        = "manara-db-subnet-group"
  description = "Database subnet group spanning multiple private subnets for Multi-AZ RDS"
  subnet_ids  = [for subnet in aws_subnet.private_db : subnet.id]

  tags = {
    Name = "manara-rds-subnet-group"
  }
}

# Multi-AZ Amazon RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier             = "manara-mysql-database"
  allocated_storage      = 20
  max_allocated_storage  = 50
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Critical High-Availability Setting
  multi_az = true

  # Storage Encryption
  storage_encrypted = true

  # Backup and Maintenance
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:30-sun:05:30"
  auto_minor_version_upgrade = true
  skip_final_snapshot       = true
  deletion_protection       = false

  tags = {
    Name = "manara-multi-az-mysql"
  }
}
