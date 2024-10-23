#!/bin/bash

echo "======================"
echo "[INFO] Starting setup..."
echo "======================"

# Update package list and upgrade
echo -e "\033[1;32m[INFO] Updating package list...\033[0m"
sudo apt update -y && sudo apt upgrade -y

# Install OpenSSH Server
echo -e "\033[1;32m[INFO] Installing OpenSSH Server...\033[0m"
sudo apt install -y openssh-server

# Create an SFTP group
echo -e "\033[1;33m[INFO] Creating SFTP group 'sftpusers'...\033[0m"
sudo groupadd sftpusers || echo "[WARN] 'sftpusers' group may already exist."

# Define users to be created
USERS=("user1" "user2" "user3" "user4")

# Create users and configure them for SFTP-only access
for USER in "${USERS[@]}"; do
  echo -e "\033[1;33m[INFO] Creating user: $USER...\033[0m"

  # Create user without password, add to 'sftpusers', and restrict SSH access
  sudo useradd -m -s /usr/sbin/nologin -G sftpusers "$USER"

  # Create SSH directory for the user
  sudo mkdir -p /home/$USER/.ssh
  # Set permissions so only the user can access it
  sudo chmod 700 /home/$USER/.ssh

  # Set placeholder for the public key (Replace this path with actual key later)
  echo "ssh-rsa AAAAB3...user-key-placeholder" | sudo tee /home/$USER/.ssh/authorized_keys > /dev/null  # Create an authorized_keys file with a placeholder for the public key
  # Set permissions for the authorized_keys file
  sudo chmod 600 /home/$USER/.ssh/authorized_keys
  # Change ownership of .ssh directory and its contents to the user
  sudo chown -R $USER:$USER /home/$USER/.ssh
  # Inform user that the user has been created and configured
  echo -e "\033[1;36m[INFO] User $USER created and configured.\033[0m"
done