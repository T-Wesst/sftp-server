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
  
  # Set the public key
  cat ~/.ssh/authorized_keys | sudo tee /home/$USER/.ssh/authorized_keys > /dev/null
  
  # Set permissions for the authorized_keys file
  sudo chmod 600 /home/$USER/.ssh/authorized_keys
  # Change ownership of .ssh directory and its contents to the user
  sudo chown -R $USER:$USER /home/$USER/.ssh

  echo -e "\033[1;33m[INFO] Creating uploads directory for $USER...\033[0m"

  # Create uploads directory for the user
  sudo mkdir -p /home/$USER/uploads
  # Change ownership to the user only
  sudo chown $USER:$USER /home/$USER/uploads
  # Set permissions to allow only the user to read/write
  sudo chmod 700 /home/$USER/uploads

  # Change ownership of the parent directory to root
  sudo chown root:root /home/$USER
  sudo chmod 755 /home/$USER

  echo -e "\033[1;36m[INFO] User $USER created and configured.\033[0m"
done

# Configure SSHD to use Chroot Jail
echo -e "\033[1;36m[INFO] Configuring SSH for SFTP-only access...\033[0m"
sudo bash -c 'cat >> /etc/ssh/sshd_config <<EOF
# SFTP configuration
Match Group sftpusers
    # Use user home directory as the chroot
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF'


# Restart SSH service to apply changes
echo -e "\033[1;32m[INFO] Restarting SSH service...\033[0m"
sudo systemctl restart ssh

echo -e "\033[1;32m[INFO] SFTP setup completed successfully!\033[0m"