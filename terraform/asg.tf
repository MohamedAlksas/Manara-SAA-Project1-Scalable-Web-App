# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "manara-web-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd php php-mysqli
              systemctl start httpd
              systemctl enable httpd
              
              TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
              INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
              AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone`
              
              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Manara SAA-C03 Project 1</title>
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; padding: 50px; background: #0f172a; color: #f8fafc; }
                  .card { background: #1e293b; border-radius: 12px; padding: 30px; max-width: 600px; margin: auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
                  h1 { color: #38bdf8; }
                  .badge { display: inline-block; background: #0284c7; color: white; padding: 6px 14px; border-radius: 20px; font-weight: bold; margin: 5px; }
                  .info { margin: 15px 0; font-size: 18px; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>🚀 High-Availability Web Application</h1>
                  <p class="info">Serving live from private compute tier!</p>
                  <p><span class="badge">Availability Zone: $AZ</span></p>
                  <p><span class="badge">Instance ID: $INSTANCE_ID</span></p>
                  <hr style="border-color: #334155; margin: 20px 0;">
                  <p style="color: #94a3b8; font-size: 14px;">AWS Solutions Architect Associate Graduation Project (Manara.tech)</p>
                  <p style="color: #64748b; font-size: 12px;">Engineered by Mohamed Alksas</p>
                </div>
              </body>
              </html>
              HTML
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "manara-asg-web-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group spanning 2 AZ Private Subnets
resource "aws_autoscaling_group" "web" {
  name_prefix         = "manara-asg-"
  vpc_zone_identifier = [for s in aws_subnet.private_app : s.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "manara-asg-app-instance"
    propagate_at_launch = true
  }
}

# Target Tracking Scaling Policy (Maintains 60% average CPU utilization)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "manara-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# Step Scaling Policy (Scale Out for rapid spike response)
resource "aws_autoscaling_policy" "step_scale_out" {
  name                   = "manara-asg-step-scale-out"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "StepScaling"
  adjustment_type        = "ChangeInCapacity"

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 25
  }

  step_adjustment {
    scaling_adjustment          = 2
    metric_interval_lower_bound = 25
  }
}

