#!/bin/bash
rm -f "$HOME/docker-services/docker-compose.yml" && echo "Docker Compose file deleted."

# Define directories and file paths for secure storage
CONFIG_DIR="$HOME/.config/credentials"
mkdir -p "$CONFIG_DIR"
PUSHBULLET_TOKEN_FILE="$CONFIG_DIR/pushbullet_token"
SAMBA_USER_FILE="$CONFIG_DIR/samba_username"
SAMBA_PASS_FILE="$CONFIG_DIR/samba_password"

#!/bin/bash

# Using ~ to denote the home directory
DOCKER_SERVICES_DIR="~/docker-services"
mkdir -p "$DOCKER_SERVICES_DIR"

DOCKER_COMPOSE_FILE="$DOCKER_SERVICES_DIR/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "version: '3'" > "$DOCKER_COMPOSE_FILE"
    echo "services:" >> "$DOCKER_COMPOSE_FILE"
fi

# Function to check and prompt for credentials
check_and_prompt_for_credential() {
    local credential_file=$1
    local credential_name=$2
    local var_name=$3
    local credential_value
    if [ -f "$credential_file" ]; then
        credential_value=$(cat "$credential_file")
    else
        read -p "Enter your $credential_name: " credential_value
        echo $credential_value > "$credential_file"
        chmod 600 "$credential_file"
    fi
    eval $var_name="'$credential_value'"
}

# Prompt for Pushbullet token, Samba username, and password
check_and_prompt_for_credential "$PUSHBULLET_TOKEN_FILE" "Pushbullet access token" PUSHBULLET_TOKEN
check_and_prompt_for_credential "$SAMBA_USER_FILE" "Samba username" USERNAME
check_and_prompt_for_credential "$SAMBA_PASS_FILE" "Samba password" PASSWORD

# Function to send notification via Pushbullet
send_pushbullet_notification() {
    local title="$1"
    local message="$2"
    local token="$PUSHBULLET_TOKEN"
    curl -u "$token:" -X POST https://api.pushbullet.com/v2/pushes \
         --header 'Content-Type: application/json' \
         --data-binary "{\"type\": \"note\", \"title\": \"$title\", \"body\": \"$message\"}"
}

# Add Docker repository and install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

# Function to properly format Docker Compose service configurations
add_service_to_docker_compose() {
  if ! grep -q "$1" "$DOCKER_COMPOSE_FILE"; then
    echo "Adding $1 service to Docker Compose file."
    cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  $1:
    container_name: $2
    image: $3
    ports:
      - "$4"
    environment:
      - $5
    volumes:
      - $6
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
        cd "$DOCKER_SERVICES_DIR" || exit
        docker compose up -d   # Note the change here from docker-compose to docker compose
        send_pushbullet_notification "Docker Update" "$1 container has been updated or restarted"
    fi
}

# Add script to crontab to run at reboot and daily at 4 AM
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
(crontab -l 2>/dev/null; echo "@reboot $SCRIPT_PATH"; echo "0 4 * * * $SCRIPT_PATH") | crontab -

# Define and check the share directory permissions
SHARE_DIR="$HOME/share"
if [ ! -d "$SHARE_DIR" ] || [ "$(stat -c '%a' "$SHARE_DIR")" != "777" ]; then
    mkdir -p "$SHARE_DIR"
    chmod 777 "$SHARE_DIR"
fi


check_and_run_service "samba" "samba" "dperson/samba" \
"[\"139:139\", \"445:445\"]" \
"USER=${USERNAME},PASSWORD=${PASSWORD},USER_ID=${USER_ID},GROUP_ID=${GROUP_ID},SHARE_NAME=${SHARE_NAME}" \
"${SHARE_DIR}:/share:rw"

check_and_run_service "pihole" "pihole" "pihole/pihole:latest" \
"[\"53:53\", \"53:53/udp\", \"67:67/udp\", \"80:80\", \"443:443\"]" \
"TZ=Pacific/Auckland,WEBPASSWORD=" \
"[\"./etc-pihole:/etc/pihole\", \"./etc-dnsmasq.d:/etc/dnsmasq.d\"]"

check_and_run_service "openvpn" "openvpn" "kylemanna/openvpn" \
"[\"1194:1194/udp\", \"943:943\"]" \
"PUID=1000,PGID=1000" \
"[\"./openvpn-data/conf:/etc/openvpn\"]"

check_and_run_service "plex" "plex" "plexinc/pms-docker" \
"[\"32400:32400\"]" \
"" \
"[\"./plex-config:/config\", \"./plex-data:/data\"]"

check_and_run_service "mumble" "mumble" "mumble-voip/mumble-server" \
"[\"64738:64738\", \"64738:64738/udp\"]" \
"" \
"[\"./mumble-data:/data\"]"

check_and_run_service "deluge" "deluge" "linuxserver/deluge" \
"[\"8112:8112\", \"58846:58846\", \"58946:58946/udp\"]" \
"" \
"[\"./deluge-config:/config\"]"

check_and_run_service "xteve" "xteve" "tellytv/xteve" \
"[\"34400:34400\"]" \
"" \
"[\"./xteve-config:/root/.xteve\"]"

check_and_run_service "homeassistant" "homeassistant" "homeassistant/home-assistant" \
"[\"8123:8123\"]" \
"" \
"[\"./homeassistant-config:/config\"]"

check_and_run_service "web-desktop" "web-desktop" "kasmweb/desktop" \
"[\"6901:6901\"]" \
"" \
"[]"  # No volumes required, provide an empty list if needed

# Deactivate commands and cleanup
echo "All services are checked and notifications are sent."
