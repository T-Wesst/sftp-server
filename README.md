# SFTP Server on AWS EC2

This project sets up a secure SFTP server on an AWS EC2 instance using Terraform to allow secure file transfers between clients and the server.

## Technologies Used
- AWS EC2 (Ubuntu Linux)
- SFTP (SSH File Transfer Protocol)
- SSH Authentication
- Security Groups

## Architecture
- EC2 Instance hosts SFTP server
- Connect over SFTP via SSH
- Security Groups allow SSH access on port 22

## Features
- Secure Encryption: Files transferred using SSH encryption.
- Cost-Efficient: No need for AWS Transfer Family.

## How It Works
## Demo