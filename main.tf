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

output "sftp_server_ip" {
  value = aws_instance.sftp-us-west-2.public_ip
}

resource "aws_instance" "sftp-us-west-2" {
  ami             = var.ami
  instance_type   = "t2.micro"
  key_name        = var.key_name
  security_groups = [aws_security_group.sftp-security_group.name]

  user_data = base64encode(file("./scripts/setup.sh"))
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    OS          = "Ubuntu"
    Name        = "SFTP Server"
    Environment = "Development"
  }

}