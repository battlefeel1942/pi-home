#!/bin/bash

# Define the path to the Docker installation script
DOCKER_INSTALL_SCRIPT="$HOME/get-docker.sh"

# Download the Docker convenience script if it doesn't exist
if [ ! -f "$DOCKER_INSTALL_SCRIPT" ]; then
    curl -fsSL https://get.docker.com -o "$DOCKER_INSTALL_SCRIPT"
fi

# Install Docker if not already installed
if ! command -v docker >/dev/null 2>&1; then
    sudo sh "$DOCKER_INSTALL_SCRIPT"
fi

# Add the current user to the 'docker' group
sudo usermod -aG docker $USER

# Unmask the Docker service to ensure it can start
sudo systemctl unmask docker.service

# Fix permissions for the Docker socket
# Note: This step may not be secure; consider your security policies before applying.
sudo chmod 666 /var/run/docker.sock

# Install Docker Compose if it doesn't exist
if ! command -v docker-compose >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y libffi-dev libssl-dev python3 python3-pip
    sudo pip3 install docker-compose
fi

# Ensure the Docker service is started
sudo systemctl start docker.service