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
  name        = "sftp-sg"
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
resource "aws_launch_configuration" "sftp-launch-config" {
  image_id        = var.ami
  name            = "sftp-launch-config"
  instance_type   = "t2.micro"
  key_name        = var.key_name
  security_groups = [aws_security_group.sftp-security_group.name]

  # Cloud-init script
  user_data = base64encode(file("./scripts/setup.sh"))
  root_block_device {
    # root block size
    volume_size = 8
    # general purpose ssd
    volume_type = "gp3"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sftp-asg" {
  name                 = "sftp-asg"
  min_size             = 1
  max_size             = 3
  desired_capacity = 1
  availability_zones = [var.region]
  
  launch_configuration = "${aws_launch_configuration.sftp-launch-config.name}"
  tag {
    key = "Environment"
    value = "Development"
    propagate_at_launch = true
  }
  tag {
    key = "Name"
    value = "SFTP Server ASG"
    propagate_at_launch = true
  }
  tag {
    key = "OS"
    value = "Ubuntu"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Network Load Balancer
resource "aws_lb" "sftp_nlb" {
  name = "sftp-nlb"
  load_balancer_type = "network"
  internal = false
  security_groups = [aws_autoscaling_group.sftp-asg]
  enable_deletion_protection = false
  tags = {
    Name = "SFTP NLB"
  }
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "sftp_target_group" {
  name = "sftp-target-group"
  port = 22
  protocol = "tcp"
  # vpc_id = 
  # target_type = instance | ip
  health_check {
    interval = 30
    port = 22
    protocol = "tcp"
    timeout = 10
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "SFTP Target Group"
  }
}

# output "sftp_server_ip" {
#   value = aws_instance.sftp-us-west-2.public_ip
# }