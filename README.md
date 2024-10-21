# SFTP Server on AWS EC2

This project sets up a secure SFTP server on an AWS EC2 instance using Terraform to allow secure file transfers between clients and the server.

## Technologies Used
- AWS EC2 (Ubuntu Linux)
- SFTP (SSH File Transfer Protocol)
- SSH Authentication
- Security Groups

## Architecture
- EC2 Instance hosts SFTP server
- Users connect over SFTP via SSH
- Security Groups allow SSH access on port 22

## Features
- Secure Encryption: Files transferred using SSH encryption.
- Cost-Efficient: No need for AWS Transfer Family.
- User Management: Easily create users with isolated directories.

## How It Works
- Users connect via SFTP clients like FileZilla or the sftp command.
- Files are uploaded/downloaded over encrypted channels.
- Optional CloudWatch monitoring can log connection attempts.


## Demo

