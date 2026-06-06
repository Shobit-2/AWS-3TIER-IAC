# Target Group for External Load Balancer
resource "aws_lb_target_group" "web_tier" {
  name        = "web-tier-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name        = "web-tier-target-group"
    Environment = var.environment
  }
}

# External Load Balancer
resource "aws_lb" "external" {
  name               = "external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.external_alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "external-alb"
    Environment = var.environment
  }
}

# External Load Balancer Listener
resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier.arn
  }
}

# Launch Template for Web Tier
resource "aws_launch_template" "web_tier" {
  name_prefix            = "web-tier-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.web_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    internal_alb_dns = var.internal_alb_dns
    s3_bucket        = var.s3_bucket_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "web-tier-instance"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group for Web Tier
resource "aws_autoscaling_group" "web_tier" {
  name                = "web-tier-asg"
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.web_tier.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web_tier.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-tier-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data sources
data "aws_vpc" "main" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_security_group" "external_alb" {
  name = "external-alb-sg"
}
