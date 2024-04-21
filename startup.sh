#!/bin/bash
rm -f "/home/pi/docker-services/docker-compose.yml" && echo "Docker Compose file deleted."


# Define directories and file paths for secure storage
CONFIG_DIR="$HOME/.config/credentials"
mkdir -p "$CONFIG_DIR"
PUSHBULLET_TOKEN_FILE="$CONFIG_DIR/pushbullet_token"
SAMBA_USER_FILE="$CONFIG_DIR/samba_username"
SAMBA_PASS_FILE="$CONFIG_DIR/samba_password"

#!/bin/bash

# Using ~ to denote the home directory
DOCKER_SERVICES_DIR="/home/pi/docker-services"
mkdir -p "$DOCKER_SERVICES_DIR"

DOCKER_COMPOSE_FILE="$DOCKER_SERVICES_DIR/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "version: '3.7'" > "$DOCKER_COMPOSE_FILE"
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

# Function to add services to Docker Compose
add_service_to_docker_compose() {
    if ! grep -q "  $1:" "$DOCKER_COMPOSE_FILE"; then  # Checking the start of a service block
        echo "Adding $1 service to Docker Compose file."
        echo "  $1:" >> "$DOCKER_COMPOSE_FILE"
        echo "    container_name: $2" >> "$DOCKER_COMPOSE_FILE"
        echo "    image: $3" >> "$DOCKER_COMPOSE_FILE"
        echo "    ports:" >> "$DOCKER_COMPOSE_FILE"
        IFS=';' read -ra PORTS <<< "$4"
        for port in "${PORTS[@]}"; do
            echo "      - $port" >> "$DOCKER_COMPOSE_FILE"
        done
        echo "    environment:" >> "$DOCKER_COMPOSE_FILE"
        IFS=',' read -ra ENV_VARS <<< "$5"
        for env in "${ENV_VARS[@]}"; do
            echo "      - $env" >> "$DOCKER_COMPOSE_FILE"
        done
        echo "    volumes:" >> "$DOCKER_COMPOSE_FILE"
        IFS=';' read -ra VOLUMES <<< "$6"
        for volume in "${VOLUMES[@]}"; do
            echo "      - $volume" >> "$DOCKER_COMPOSE_FILE"
        done
        echo "    cap_add:" >> "$DOCKER_COMPOSE_FILE"
        echo "      - NET_ADMIN" >> "$DOCKER_COMPOSE_FILE"
        echo "    restart: unless-stopped" >> "$DOCKER_COMPOSE_FILE"
    else
        echo "$1 service already exists in Docker Compose file."
    fi
}

# Enhanced function to check and run services and send notifications
check_and_run_service() {
    if ! docker ps | grep -q $1; then
        add_service_to_docker_compose "$@"
        cd "$DOCKER_SERVICES_DIR" || exit
        docker compose up -d
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

# Check and run predefined services
check_and_run_service "samba" "samba" "dperson/samba" \
"139:139;445:445" \
"USER=${USERNAME},PASSWORD=${PASSWORD},USER_ID=${USER_ID},GROUP_ID=${GROUP_ID},SHARE_NAME=${SHARE_NAME}" \
"${SHARE_DIR}:/share:rw"

check_and_run_service "pihole" "pihole" "pihole/pihole:latest" \
"53:53;53:53/udp;67:67/udp;80:80;443:443" \
"TZ=Pacific/Auckland,WEBPASSWORD=" \
"./etc-pihole:/etc/pihole;./etc-dnsmasq.d:/etc/dnsmasq.d"

check_and_run_service "openvpn" "openvpn" "lunderhage/openvpn" \
"1194:1194/udp;943:943" \
"PUID=1000,PGID=1000" \
"./openvpn-data/conf:/etc/openvpn"

echo "All services are checked and notifications are sent."
