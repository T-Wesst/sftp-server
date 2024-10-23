terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}
# Security Group
resource "aws_security_group" "sftp-security_group" {
  name        = "sftp_sg"
  description = "Allow SSH and SFTP access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ip]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SFTP Security Group"
  }
}

# Launch Configuration
resource "aws_launch_template" "sftp-launch-config" {
  image_id      = var.ami
  name          = "sftp-launch-config"
  instance_type = "t2.micro"
  key_name      = var.key_name
  description   = "SFTP Server Template"
  # Cloud-init script
  user_data = base64encode(file("./scripts/setup.sh"))

  network_interfaces {
    subnet_id                   = var.subnet_id
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sftp-security_group.id]
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      # root block size
      volume_size = 8
      # general purpose ssd
      volume_type = "gp3"

    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      OS          = "Ubuntu"
      Name        = "SFTP Server"
      Environment = "Development"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Network Load Balancer
resource "aws_lb" "sftp_nlb" {
  name                       = "sftp-nlb"
  load_balancer_type         = "network"
  internal                   = false
  enable_deletion_protection = false
  subnet_mapping {
    subnet_id = var.subnet_id
  }
  tags = {
    Name = "SFTP NLB"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sftp-asg" {
  name                = "sftp-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = [var.subnet_id]
  launch_template {
    id      = aws_launch_template.sftp-launch-config.id
    version = "$Latest"
  }

  health_check_type = "ELB"
  target_group_arns = ["${aws_lb_target_group.sftp_target_group.arn}"]
  tag {
    key                 = "Name"
    value               = "SFTP Server ASG Instance"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
# Attach Auto Scaling Group to Target Group
resource "aws_autoscaling_attachment" "sftp_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.sftp-asg.id
  lb_target_group_arn    = aws_lb_target_group.sftp_target_group.arn
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "sftp_target_group" {
  name     = "sftp-target-group"
  port     = 22
  protocol = "TCP"
  vpc_id   = var.vpc_id
  # target_type = instance | ip
  health_check {
    interval            = 30
    port                = 22
    protocol            = "TCP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "SFTP Target Group"
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "sftp_lister" {
  load_balancer_arn = aws_lb.sftp_nlb.arn
  port              = 22
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sftp_target_group.arn
  }
}

# Output for the Auto Scaling Group
output "sftp_asg_instance_ids" {
  value = aws_autoscaling_group.sftp-asg.id
}