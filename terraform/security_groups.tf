# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "manara-alb-sg"
  description = "Security Group for Internet-facing Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow outbound to App Servers on Port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "manara-alb-security-group"
  }
}

# Security Group for EC2 Application Tier
resource "aws_security_group" "app" {
  name        = "manara-app-sg"
  description = "Security Group for Private Application Tier EC2 Instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP strictly from ALB Security Group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic for OS updates and packages via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "manara-app-security-group"
  }
}

# Security Group for RDS Database Tier
resource "aws_security_group" "db" {
  name        = "manara-db-sg"
  description = "Security Group for Private Amazon RDS Multi-AZ Database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL traffic strictly from App Security Group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "No outbound access required"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "manara-db-security-group"
  }
}
