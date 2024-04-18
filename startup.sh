#!/bin/bash

# Update and upgrade the system
sudo apt-get update && sudo apt-get upgrade -y

# Check if Docker is installed and install if it isn't
if ! [ -x "$(command -v docker)" ]; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo systemctl restart
fi

# Function to update all running Docker containers
update_docker_containers() {
  docker-compose pull
  docker-compose up -d
}

# Check if Docker Compose is installed, if not install it
if ! [ -x "$(command -v docker-compose)" ]; then
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Update Docker containers
update_docker_containers

# Check if Pi-hole is running, install and start if it isn't
if ! docker ps | grep -q pihole; then
  # Assuming docker-compose.yml is setup for Pi-hole
  docker-compose -f /path/to/pihole/docker-compose.yml up -d
  sudo systemctl restart
fi

