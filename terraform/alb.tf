# Application Load Balancer
resource "aws_lb" "main" {
  name               = "manara-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "manara-application-load-balancer"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "web" {
  name                 = "manara-web-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "manara-web-target-group"
  }
}

# ALB HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Layer 7 Listener Rule: Application Path-Based Routing (/app/*, /index.html)
resource "aws_lb_listener_rule" "app_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  condition {
    path_pattern {
      values = ["/index.html", "/app/*"]
    }
  }
}

# Layer 7 Listener Rule: Dedicated Health Check endpoint (/healthz) returning 200 OK
resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ALB Layer 7 Health Check OK"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/healthz", "/ping"]
    }
  }
}

