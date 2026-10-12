# ==============================================================================
# Network Access Control Lists (NACLs) - Stateless Subnet Security Layer
# Defense-in-Depth: Subnet-level stateless filtering before Security Groups
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Public Subnets NACL (ALB & NAT Gateways)
# ------------------------------------------------------------------------------
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.public : s.id]

  # Inbound Rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral return traffic from the internet to NAT Gateways / ALB
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "manara-public-nacl"
    Tier = "Public"
  }
}

# ------------------------------------------------------------------------------
# 2. Private Application Subnets NACL (Auto-Scaled EC2 Web Servers)
# ------------------------------------------------------------------------------
resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.private_app : s.id]

  # Inbound: HTTP traffic from within the VPC (specifically forwarded by ALB)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 80
    to_port    = 80
  }

  # Inbound: Ephemeral return traffic from NAT Gateways (for yum updates, packages)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: Internet egress via NAT Gateways (HTTP/HTTPS for packages and SSM)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Outbound: MySQL traffic to Database Subnets
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 3306
    to_port    = 3306
  }

  # Outbound: Ephemeral return traffic back to ALB
  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "manara-private-app-nacl"
    Tier = "Private-App"
  }
}

# ------------------------------------------------------------------------------
# 3. Private Database Subnets NACL (Amazon RDS MySQL Multi-AZ)
# ------------------------------------------------------------------------------
resource "aws_network_acl" "private_db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.private_db : s.id]

  # Inbound: MySQL traffic strictly from within the VPC (App Tier)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 3306
    to_port    = 3306
  }

  # Outbound: Ephemeral return traffic strictly back to App Tier within VPC
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "manara-private-db-nacl"
    Tier = "Private-DB"
  }
}
