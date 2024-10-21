terraform {
  required_providers {
    aws = {
        source = "hashicopr/aws"
        version = "~>4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
    region = "us-west-2"
  
}

resource "aws_instance" "sftp-us-west-2" {
    ami = "ami-04dd23e62ed049936"
    instance_type = "t2.micro"
    security_groups = ["sftp-sg"]
    root_block_devices {
        volume_size = 8
        volume_type = "gp3"
    }
    tags = {
        OS = "Ubuntu"
        Application = "SFTP Server"
        Name = "SFTP Server"
        Environment = "Development"
    }
  
}