#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Get username and password from user
echo "Please enter the username for the new XRDP user:"
read newuser
echo "Please enter the password for the new XRDP user:"
read -s newpass

# Create new user and add password
echo "Creating user $newuser..."
useradd -m -s /bin/bash $newuser
echo $newuser:$newpass | chpasswd

# Update and upgrade the system
echo "Updating and upgrading your system. This may take a while..."
sudo apt-get update && sudo apt-get upgrade -y

# Install XRDP and XFCE
echo "Installing XRDP and XFCE4..."
sudo apt-get install xrdp xfce4 xfce4-goodies -y

# Set XFCE as the desktop environment for XRDP
echo "Configuring XRDP to use XFCE..."
echo xfce4-session > /home/$newuser/.xsession
chown $newuser:$newuser /home/$newuser/.xsession

# Restart XRDP to apply changes
echo "Enabling and restarting XRDP..."
sudo systemctl enable xrdp
sudo systemctl restart xrdp

echo "Setup completed. XRDP is now configured for user $newuser."
