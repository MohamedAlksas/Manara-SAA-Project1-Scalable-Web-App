# SNS Topic for System Alarms & Notifications
resource "aws_sns_topic" "alerts" {
  name = "manara-system-alerts-topic"

  tags = {
    Name = "manara-sns-alerts"
  }
}

# SNS Subscription (Sends email alert to admin)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm: High ASG CPU Utilization (> 75%)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "manara-asg-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Triggered when average CPU exceeds 75% across the web tier"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# CloudWatch Alarm: ALB Target 5XX Server Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "manara-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggered if more than 10 HTTP 5xx responses occur within 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# ------------------------------------------------------------------------------
# Operational CloudWatch Dashboard
# Visualizes Key Metrics: ASG CPU, ALB Requests & Errors, Latency, RDS Connections
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "manara-scalable-webapp-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name, { stat = "Average", label = "ASG CPU Utilization (%)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Web Tier (ASG) - Average CPU Utilization"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Sum", label = "Total Requests" }],
            [".", "HTTPCode_Target_2XX_Count", ".", ".", { stat = "Sum", label = "HTTP 2XX (Success)" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum", label = "HTTP 5XX (Server Errors)", color = "#d62728" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Application Load Balancer - Request Volume & Status Codes"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "Average", label = "Target Response Time (s)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Application Latency - Target Response Time"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mysql.identifier, { stat = "Average", label = "Active DB Connections" }],
            [".", "CPUUtilization", ".", ".", { stat = "Average", label = "RDS CPU Utilization (%)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Amazon RDS MySQL Multi-AZ - Connections & CPU"
        }
      }
    ]
  })
}
