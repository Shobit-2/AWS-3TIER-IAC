# Target Group for Internal Load Balancer
resource "aws_lb_target_group" "app_tier" {
  name        = "app-tier-tg"
  port        = 4000
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
    Name        = "app-tier-target-group"
    Environment = var.environment
  }
}

# Internal Load Balancer
resource "aws_lb" "internal" {
  name               = "internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.internal_alb.id]
  subnets            = var.private_app_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "internal-alb"
    Environment = var.environment
  }
}

# Internal Load Balancer Listener
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier.arn
  }
}

# Launch Template for App Tier
resource "aws_launch_template" "app_tier" {
  name_prefix            = "app-tier-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint   = var.db_endpoint
    db_username   = var.db_username
    db_password   = var.db_password
    s3_bucket     = var.s3_bucket_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-tier-instance"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group for App Tier
resource "aws_autoscaling_group" "app_tier" {
  name                = "app-tier-asg"
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app_tier.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-tier-asg"
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

data "aws_security_group" "internal_alb" {
  name = "internal-alb-sg"
}
