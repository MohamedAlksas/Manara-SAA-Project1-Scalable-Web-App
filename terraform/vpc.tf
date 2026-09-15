# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "manara-scalable-vpc"
  }
}

# Internet Gateway for Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "manara-igw"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_1a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "manara-nat-eip-1a"
  }
}

resource "aws_eip" "nat_eip_1b" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "manara-nat-eip-1b"
  }
}

# High-Availability Dual NAT Gateways (One per AZ)
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_eip_1a.id
  subnet_id     = aws_subnet.public["us-east-1a"].id

  tags = {
    Name = "manara-nat-gw-1a"
  }
}

resource "aws_nat_gateway" "nat_1b" {
  allocation_id = aws_eip.nat_eip_1b.id
  subnet_id     = aws_subnet.public["us-east-1b"].id

  tags = {
    Name = "manara-nat-gw-1b"
  }
}

# Public Route Table (Routes all outbound traffic to IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "manara-public-rt"
  }
}

# Private Route Tables (Routes private app traffic to respective AZ NAT Gateway)
resource "aws_route_table" "private_app_1a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "manara-private-app-rt-1a"
  }
}

resource "aws_route_table" "private_app_1b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1b.id
  }

  tags = {
    Name = "manara-private-app-rt-1b"
  }
}

# Isolated DB Route Table (No internet route for maximum security)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "manara-private-db-rt"
  }
}
