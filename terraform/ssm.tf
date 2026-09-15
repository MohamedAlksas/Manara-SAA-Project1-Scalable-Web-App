# IAM Role for EC2 Instances to enable AWS Systems Manager (SSM)
resource "aws_iam_role" "ssm" {
  name = "manara-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "manara-ssm-role"
  }
}

# Attach AWS managed policy for SSM Core (enables Session Manager)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile attached to EC2 Launch Template
resource "aws_iam_instance_profile" "ssm" {
  name = "manara-ec2-ssm-instance-profile"
  role = aws_iam_role.ssm.name
}
