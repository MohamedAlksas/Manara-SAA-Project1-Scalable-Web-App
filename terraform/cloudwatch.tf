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
