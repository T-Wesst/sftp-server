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
resource "aws_security_group" "sftp-security-group" {
  name        = "sftp_sg"
  description = "Allow SSH and SFTP access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ip]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
  tags = {
    Name        = "SFTP Security Group"
    Environment = "Development"
  }
}

# Launch Configuration
resource "aws_launch_template" "sftp-launch-config" {
  name                   = "sftp-launch-config"
  image_id               = var.ami
  instance_type          = "t2.micro"
  key_name               = var.key_name
  description            = "SFTP Server Template"
  vpc_security_group_ids = [aws_security_group.sftp-security-group.id]

  # Cloud-init script
  user_data = base64encode(file("./scripts/setup.sh"))
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
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
  load_balancer_type               = "network"
  name                             = "sftp-nlb"
  internal                         = false
  ip_address_type                  = "ipv4"
  subnets                          = [var.subnet_id]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "SFTP NLB"
  }
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "sftp_target_group" {
  name                   = "sftp-target-group"
  port                   = 22
  protocol               = "TCP"
  vpc_id                 = var.vpc_id
  ip_address_type        = "ipv4"
  target_type            = "instance"
  connection_termination = true
  deregistration_delay   = 300

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 22
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }
  tags = {
    Name = "SFTP Target Group"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sftp-asg" {
  name             = "sftp-asg"
  desired_capacity = 1
  min_size         = 1
  max_size         = 3
  launch_template {
    id      = aws_launch_template.sftp-launch-config.id
    version = "$Latest"
  }
  vpc_zone_identifier       = [var.subnet_id]
  target_group_arns         = [aws_lb_target_group.sftp_target_group.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "SFTP Server ASG Instance"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "sftp_lister" {
  protocol          = "TCP"
  port              = 22
  load_balancer_arn = aws_lb.sftp_nlb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sftp_target_group.arn
  }
  tags = {
    Name = "SFTP NLB Listener"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:Name"
    values = ["SFTP Server ASG Instance"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

output "load_balancer_dns_name" {
  description = "DNS name of the SFTP Load balancer"
  value       = aws_lb.sftp_nlb.dns_name
}

output "asg_instances_public_ip" {
  description = "SFTP Server Public IPs"
  value       = data.aws_instances.asg_instances.public_ips
}

output "default_vpc_cidr_block" {
  description = "Default VPC CIDR block"
  value       = data.aws_vpc.default.cidr_block
}