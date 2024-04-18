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

# Start services if not running
check_and_run_service() {
  if ! docker ps | grep -q $1; then
    add_service_to_docker_compose "$@"
    cd ~/docker-services
    docker-compose up -d
    sudo systemctl reboot
  fi
}

# Setup Ubuntu with SSH and Python
check_and_run_service "ubuntu-ssh-python" "ubuntu-ssh-python" "ubuntu:latest" "2222:22" "" ""
docker exec ubuntu-ssh-python apt-get update
docker exec ubuntu-ssh-python apt-get install -y openssh-server python3 python3-pip
docker exec ubuntu-ssh-python service ssh start

# Setup Pi-hole with no password
check_and_run_service "pihole" "pihole" "pihole/pihole:latest" "53:53/tcp;53:53/udp;67:67/udp;80:80/tcp;443:443/tcp" "TZ:'Pacific/Auckland';WEBPASSWORD=''" "./etc-pihole/:/etc/pihole/;./etc-dnsmasq.d/:/etc/dnsmasq.d/"

# Setup OpenVPN with WebUI
check_and_run_service "openvpn" "openvpn" "kylemanna/openvpn" "1194:1194/udp;943:943/tcp" "PUID:1000;PGID:1000" "./openvpn-data/conf:/etc/openvpn"

# Setup Plex
check_and_run_service "plex" "plex" "plexinc/pms-docker" "32400:32400/tcp" "" "./plex-config:/config;./plex-data:/data"

# Setup Mumble
check_and_run_service "mumble" "mumble" "mumble-voip/mumble-server" "64738:64738/tcp;64738:64738/udp" "" "./mumble-data:/data"

# Setup Deluge with WebUI
check_and_run_service "deluge" "deluge" "linuxserver/deluge" "8112:8112/tcp;58846:58846/tcp;58946:58946/udp" "" "./deluge-config:/config"

# Setup xTeVe
check_and_run_service "xteve" "xteve" "tellytv/xteve" "34400:34400/tcp" "" "./xteve-config:/root/.xteve"

# Setup Home Assistant
check_and_run_service "homeassistant" "homeassistant" "homeassistant/home-assistant" "8123:8123/tcp" "" "./homeassistant-config:/config"

# Setup Freqtrade
check_and_run_service "freqtrade" "freqtrade" "freqtrade/freqtrade:stable" "" "FT_CONFIGFILE:'/freqtrade/config.json';FT_STRATEGY:'SampleStrategy'" "./freqtrade-config:/freqtrade"

# Setup Ubuntu Desktop with kasmweb/desktop as web-desktop
check_and_run_service "web-desktop" "web-desktop" "kasmweb/desktop" "6901:6901" "" ""

# Create Samba share directory
SHARE_DIR="/home/pi/share"
mkdir -p ${SHARE_DIR}

# Setup Samba Network Share with secure credentials
USERNAME="pi"
PASSWORD="strong_password_here!"  # Change this to a strong, unique password.
USER_ID="1000"
GROUP_ID="1000"
SHARE_NAME="share"

check_and_run_service "samba" "samba" "dperson/samba" "139:139/tcp;445:445/tcp" "USER:'$USERNAME;$PASSWORD;$USER_ID;$GROUP_ID;$SHARE_NAME'" "${SHARE_DIR}:/share:rw"
