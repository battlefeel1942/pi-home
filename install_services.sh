#!/bin/bash

# Installation of All Services

# Update system and install prerequisites
sudo apt update && sudo apt upgrade -y
sudo apt install python3-venv python3-pip apt-transport-https curl -y

# Home Assistant installation
mkdir -p ~/homeassistant
cd ~/homeassistant
python3 -m venv .
source bin/activate
pip3 install wheel
pip3 install homeassistant
deactivate

# Create systemd service file for Home Assistant
HA_PATH="/home/pi/homeassistant"
cat <<EOF | sudo tee /etc/systemd/system/homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=pi
Environment="VIRTUAL_ENV=$HA_PATH"
Environment="PATH=$HA_PATH/bin:\$PATH"
ExecStart=$HA_PATH/bin/hass -c $HA_PATH

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Home Assistant
sudo systemctl daemon-reload
sudo systemctl enable homeassistant
sudo systemctl start homeassistant

# ESPHome installation
mkdir -p ~/esphome_venv
cd ~/esphome_venv
python3 -m venv .
source bin/activate
pip3 install esphome
deactivate

# Pi-hole installation
# Consider security best practices as previously mentioned
curl -sSL https://install.pi-hole.net | bash

# Plex Media Server installation
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
User=pi
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
User=pi
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
