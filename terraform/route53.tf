# Route 53 Public Hosted Zone (Optional / Demo)
resource "aws_route53_zone" "primary" {
  name          = var.domain_name
  comment       = "Hosted Zone for Manara SAA-C03 Project 1"
  force_destroy = false

  tags = {
    Name = "manara-route53-zone"
  }
}

# Route 53 Alias Record pointing Apex domain directly to CloudFront CDN
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 Alias Record pointing directly to ALB (satisfies 'Alias record pointing to ALB')
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "alb.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Route 53 Health Check monitoring ALB endpoint
resource "aws_route53_health_check" "alb_health" {
  fqdn              = aws_lb.main.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "manara-alb-route53-health-check"
  }
}
