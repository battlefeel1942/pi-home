#!/bin/bash

# Maintenance and update script

# Update the system
sudo apt update && sudo apt upgrade -y

# Update Pi-hole
pihole -up

# Update ESPHome
sudo pip3 install --upgrade esphome

# Check and restart services if not running
systemctl is-active --quiet homeassistant || systemctl restart homeassistant
systemctl is-active --quiet esphome || systemctl restart esphome
pihole status || pihole restartdns
systemctl is-active --quiet plexmediaserver || systemctl restart plexmediaserver
systemctl is-active --quiet mumble-server || systemctl restart mumble-server
systemctl is-active --quiet deluged || systemctl restart deluged
systemctl is-active --quiet deluge-web || systemctl restart deluge-web

echo "Maintenance tasks completed."
