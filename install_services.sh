#!/bin/bash

# Installation of All Services

# Home Assistant installation
sudo apt update && sudo apt upgrade -y
sudo apt install python3-venv python3-pip -y
mkdir ~/homeassistant
cd ~/homeassistant
python3 -m venv .
source bin/activate
pip3 install wheel
pip3 install homeassistant

# Install ESPHome
python3 -m pip install esphome

# Create systemd service file for Home Assistant
cat <<EOF | sudo tee /etc/systemd/system/homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$(pwd)/bin/hass -c "$(pwd)"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Home Assistant
sudo systemctl daemon-reload
sudo systemctl enable homeassistant
sudo systemctl start homeassistant

# Pi-hole installation
curl -sSL https://install.pi-hole.net | bash

# Plex Media Server installation
sudo apt install apt-transport-https curl -y
curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/plex-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
sudo apt update
sudo apt install plexmediaserver -y
sudo systemctl enable plexmediaserver

# Mumble Server (Murmur) installation
sudo apt install mumble-server -y
sudo dpkg-reconfigure mumble-server
sudo systemctl enable mumble-server
sudo systemctl start mumble-server

# Deluge with Web UI installation
sudo apt install deluged deluge-web -y
# Deluge daemon
cat <<EOF | sudo tee /etc/systemd/system/deluged.service
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/deluged -d

[Install]
WantedBy=multi-user.target
EOF

# Deluge Web UI
cat <<EOF | sudo tee /etc/systemd/system/deluge-web.service
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=deluged.service

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/deluge-web

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Deluge services
sudo systemctl daemon-reload
sudo systemctl enable deluged deluge-web
sudo systemctl start deluged deluge-web

# Return to home directory
cd ~

# Setup cron job to run this script hourly
(crontab -l 2>/dev/null; echo "0 * * * * /home/pi/maintain_services.sh >> /home/pi/service_maintenance.log 2>&1") | crontab -
