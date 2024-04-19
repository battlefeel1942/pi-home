#!/bin/bash

# Define directories and file paths for secure storage
CONFIG_DIR="$HOME/.config/credentials"
mkdir -p "$CONFIG_DIR"
PUSHBULLET_TOKEN_FILE="$CONFIG_DIR/pushbullet_token"
SAMBA_USER_FILE="$CONFIG_DIR/samba_username"
SAMBA_PASS_FILE="$CONFIG_DIR/samba_password"

# Check if the Pushbullet token file exists and read from it, if not, prompt for it and save
if [ -f "$PUSHBULLET_TOKEN_FILE" ]; then
    PUSHBULLET_TOKEN=$(cat "$PUSHBULLET_TOKEN_FILE")
else
    read -sp "Enter your Pushbullet access token: " PUSHBULLET_TOKEN
    echo
    echo "$PUSHBULLET_TOKEN" > "$PUSHBULLET_TOKEN_FILE"
    chmod 600 "$PUSHBULLET_TOKEN_FILE"
fi

# Function to send notification via Pushbullet
send_pushbullet_notification() {
    local title="$1"
    local message="$2"
    local token="$PUSHBULLET_TOKEN"

    curl -u "$token:" -X POST https://api.pushbullet.com/v2/pushes \
        --header 'Content-Type: application/json' \
        --data-binary "{\"type\": \"note\", \"title\": \"$title\", \"body\": \"$message\"}"
}

# Check and prompt for Samba username and password
if [ -f "$SAMBA_USER_FILE" ]; then
    USERNAME=$(cat "$SAMBA_USER_FILE")
else
    read -p "Enter your Samba username: " USERNAME
    echo "$USERNAME" > "$SAMBA_USER_FILE"
    chmod 600 "$SAMBA_USER_FILE"
fi

if [ -f "$SAMBA_PASS_FILE" ]; then
    PASSWORD=$(cat "$SAMBA_PASS_FILE")
else
    read -sp "Enter your Samba password: " PASSWORD
    echo
    echo "$PASSWORD" > "$SAMBA_PASS_FILE"
    chmod 600 "$SAMBA_PASS_FILE"
fi

# Add script to crontab to run at reboot and daily at 4 AM
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
(crontab -l 2>/dev/null; echo "@reboot $SCRIPT_PATH"; echo "0 4 * * * $SCRIPT_PATH") | crontab -

# Update and upgrade the system
sudo apt-get update && sudo apt-get upgrade -y

# Ensure SSH is enabled and started
sudo systemctl enable ssh
sudo systemctl start ssh

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

# Enhanced function to check and run services and send notifications
check_and_run_service() {
    if ! docker ps | grep -q $1; then
        add_service_to_docker_compose "$@"
        cd ~/docker-services
        docker-compose up -d
        send_pushbullet_notification "Docker Update" "$1 container has been updated or restarted"
        sudo systemctl reboot
    fi
}

# Setup Samba Network Share with secure credentials
USER_ID="1000"
GROUP_ID="1000"
SHARE_NAME="share"

# Define the share directory
SHARE_DIR="$HOME/share"

# Check if the directory exists
if [ ! -d "$SHARE_DIR" ]; then
    # If it doesn't exist, create it and set permissions
    mkdir -p "$SHARE_DIR"
    chmod 777 "$SHARE_DIR"
else
    # If it exists, check the current permissions
    current_perms=$(stat -c "%a" "$SHARE_DIR")
    if [ "$current_perms" != "777" ]; then
        # If permissions are not 777, change them
        chmod 777 "$SHARE_DIR"
    fi
fi
check_and_run_service "samba" "samba" "dperson/samba" "139:139/tcp;445:445/tcp" "USER:'$USERNAME;$PASSWORD;$USER_ID;$GROUP_ID;$SHARE_NAME'" "${SHARE_DIR}:/share:rw"

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

# Setup Ubuntu Desktop with kasmweb/desktop as web-desktop
check_and_run_service "web-desktop" "web-desktop" "kasmweb/desktop" "6901:6901" "" ""