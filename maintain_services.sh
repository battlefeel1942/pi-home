#!/bin/bash

# Maintenance and update script

# Update the system
sudo apt update && sudo apt upgrade -y

# Update Pi-hole
if [ -x /usr/local/bin/pihole ]; then
    /usr/local/bin/pihole -up
else
    echo "Pi-hole command not found. Skipping Pi-hole update."
fi

# Update ESPHome
if command -v esphome &> /dev/null
then
    sudo pip3 install --upgrade esphome
else
    echo "ESPHome command not found. Skipping ESPHome update."
fi

# Check and restart services if not running
systemctl is-active --quiet homeassistant || systemctl restart homeassistant

if systemctl list-units --full -all | grep -Fq 'esphome.service'; then
    systemctl is-active --quiet esphome || systemctl restart esphome
else
    echo "ESPHome service not found."
fi

if [ -x /usr/local/bin/pihole ]; then
    /usr/local/bin/pihole status || /usr/local/bin/pihole restartdns
else
    echo "Pi-hole command not found. Skipping Pi-hole DNS restart."
fi

systemctl is-active --quiet plexmediaserver || systemctl restart plexmediaserver
systemctl is-active --quiet mumble-server || systemctl restart mumble-server
systemctl is-active --quiet deluged || systemctl restart deluged
systemctl is-active --quiet deluge-web || systemctl restart deluge-web

echo "Maintenance tasks completed."