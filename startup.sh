#!/bin/bash

# Update and upgrade the system
sudo apt-get update && sudo apt-get upgrade -y

# Check if Docker is installed and install if it isn't
if ! [ -x "$(command -v docker)" ]; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  mkdir -p ~/docker-services
  touch ~/docker-services/docker-compose.yml
  cat <<EOF > ~/docker-services/docker-compose.yml
version: '3'
services:
EOF
  sudo systemctl reboot
fi

# Check if Docker Compose is installed, if not install it
if ! [ -x "$(command -v docker-compose)" ]; then
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Function to update docker-compose.yml with a new service
add_service_to_docker_compose() {
  if ! grep -q "$1" ~/docker-services/docker-compose.yml; then
    cat <<EOF >> ~/docker-services/docker-compose.yml
  $1:
    container_name: $2
    image: $3
    ports:
      $(echo "$4" | sed 's/;/\n      /g')
    environment:
      $(echo "$5" | sed 's/;/\n      /g')
    volumes:
      $(echo "$6" | sed 's/;/\n      /g')
    cap_add:
      - NET_ADMIN
    restart: unless-stopped

EOF
  fi
}

# Setup Pi-hole if not already setup
if ! docker ps | grep -q pihole; then
  add_service_to_docker_compose "pihole" "pihole" "pihole/pihole:latest" "53:53/tcp;53:53/udp;67:67/udp;80:80/tcp;443:443/tcp" "TZ:'Pacific/Auckland';WEBPASSWORD:'set_your_password_here'" "./etc-pihole/:/etc/pihole/;./etc-dnsmasq.d/:/etc/dnsmasq.d/"
  cd ~/docker-services
  docker-compose up -d
  sudo systemctl reboot
fi

# Setup OpenVPN if not already setup
if ! docker ps | grep -q openvpn; then
  add_service_to_docker_compose "openvpn" "openvpn" "kylemanna/openvpn" "1194:1194/udp" "" "./openvpn-data/conf:/etc/openvpn"
  cd ~/docker-services
  docker-compose up -d
  sudo systemctl reboot
fi
