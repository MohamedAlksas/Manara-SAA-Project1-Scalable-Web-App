# Public Subnets across 2 AZs (ALB & NAT Gateways)
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "manara-public-subnet-${each.key}"
    Type = "Public"
  }
}

# Private Application Subnets across 2 AZs (Auto-Scaled EC2 Web Servers)
resource "aws_subnet" "private_app" {
  for_each                = var.private_app_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name = "manara-private-app-${each.key}"
    Type = "Private-App"
  }
}

# Private Database Subnets across 2 AZs (Multi-AZ RDS MySQL)
resource "aws_subnet" "private_db" {
  for_each                = var.private_db_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name = "manara-private-db-${each.key}"
    Type = "Private-DB"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations for Private App Subnets (HA NAT routing)
resource "aws_route_table_association" "private_app_1a" {
  subnet_id      = aws_subnet.private_app["us-east-1a"].id
  route_table_id = aws_route_table.private_app_1a.id
}

resource "aws_route_table_association" "private_app_1b" {
  subnet_id      = aws_subnet.private_app["us-east-1b"].id
  route_table_id = aws_route_table.private_app_1b.id
}

# Route Table Associations for Private DB Subnets
resource "aws_route_table_association" "private_db" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}
