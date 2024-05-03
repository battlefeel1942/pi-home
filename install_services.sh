#!/bin/bash

# Installation of All Services

# Update system and install prerequisites
sudo apt update && sudo apt upgrade -y
sudo apt install python3-venv python3-pip apt-transport-https curl -y

# Set the username for installations
USER=pi

# Home Assistant installation in the user's home directory
HA_PATH="/home/$USER/homeassistant"
sudo mkdir -p $HA_PATH
sudo chown $USER:$USER $HA_PATH

# Run Home Assistant installation as specified user
sudo -u $USER bash <<EOF
cd $HA_PATH
python3 -m venv .
source bin/activate
pip3 install psutil
pip3 install wheel
pip3 install homeassistant
deactivate
EOF

# Create systemd service file for Home Assistant
sudo tee /etc/systemd/system/homeassistant.service > /dev/null << EOF
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=$USER
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
ESPHOME_PATH="/home/$USER/esphome_venv"
sudo mkdir -p $ESPHOME_PATH
sudo chown $USER:$USER $ESPHOME_PATH

sudo -u $USER bash <<EOF
cd $ESPHOME_PATH
python3 -m venv .
source bin/activate
pip3 install esphome
deactivate
EOF

# Pi-hole installation
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
sudo adduser --disabled-password --system --home /var/lib/deluge --gecos "Deluge service" --group deluge
sudo touch /var/log/deluged.log
sudo touch /var/log/deluge-web.log
sudo chown deluge:deluge /var/log/deluge*
sudo apt update
sudo apt install deluged deluge-web -y
# Deluge daemon
sudo tee /etc/systemd/system/deluged.service > /dev/null <<EOF
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=000
ExecStart=/usr/bin/deluged -d
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

# Deluge Web UI
sudo tee /etc/systemd/system/deluge-web.service > /dev/null <<EOF
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=027
ExecStart=/usr/bin/deluge-web -d
Restart=on-failure

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
(crontab -l 2>/dev/null; echo "0 * * * * /home/$USER/maintain_services.sh >> /home/$USER/service_maintenance.log 2>&1") | crontab -
