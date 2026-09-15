# AWS WAFv2 Web ACL to protect ALB against OWASP Top 10
resource "aws_wafv2_web_acl" "main" {
  name        = "manara-alb-waf"
  description = "AWS WAF Web ACL protecting ALB against SQL injection, XSS, and OWASP Top 10"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Core Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "manaraWAFCommonRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule to prevent HTTP floods / DDoS (Max 1000 requests per 5 mins per IP)
  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "manaraWAFRateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "manaraWebACLMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "manara-waf-web-acl"
  }
}

# Associate WAF Web ACL directly with the Application Load Balancer
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
