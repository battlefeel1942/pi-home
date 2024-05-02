
# Raspberry Pi Services Installation and Maintenance

## Part 1: Installation of All Services

### Home Assistant
- Update your system and install necessary packages:
  ```bash
  sudo apt update && sudo apt upgrade -y
  sudo apt install python3-venv python3-pip -y
  ```
- Create a directory, setup virtual environment, and install Home Assistant:
  ```bash
  mkdir ~/homeassistant
  cd ~/homeassistant
  python3 -m venv .
  source bin/activate
  pip3 install wheel
  pip3 install homeassistant
  hass
  ```

### Pi-hole
- Install Pi-hole using the automated script:
  ```bash
  curl -sSL https://install.pi-hole.net | bash
  ```

### Plex Media Server
- Install Plex Media Server:
  ```bash
  sudo apt install apt-transport-https curl -y
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
  echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
  sudo apt update
  sudo apt install plexmediaserver -y
  ```

### Mumble Server (Murmur)
- Install and configure Mumble Server:
  ```bash
  sudo apt install mumble-server -y
  sudo dpkg-reconfigure mumble-server
  sudo systemctl enable mumble-server
  sudo systemctl start mumble-server
  ```

### Deluge with Web UI
- Install Deluge and its Web UI:
  ```bash
  sudo apt install deluged deluge-web -y
  deluged
  deluge-web &
  ```

## Part 2: Bash Script for Service Maintenance

Create a script to ensure all services are running and the system is up to date:
- Script content:
  ```bash
  #!/bin/bash
  
  # Update the system
  sudo apt update && sudo apt upgrade -y

  # Check and restart Home Assistant if not running
  systemctl is-active --quiet homeassistant || systemctl restart homeassistant

  # Check and restart Pi-hole if not running
  pihole status || pihole restartdns

  # Check and restart Plex Media Server if not running
  systemctl is-active --quiet plexmediaserver || systemctl restart plexmediaserver

  # Check and restart Mumble Server if not running
  systemctl is-active --quiet mumble-server || systemctl restart mumble-server

  # Check and restart Deluge Daemon if not running
  systemctl is-active --quiet deluged || systemctl restart deluged

  # Check and restart Deluge Web UI if not running
  systemctl is-active --quiet deluge-web || systemctl restart deluge-web
  ```

- Make the script executable and schedule it with Cron:
  ```bash
  chmod +x ~/service_maintenance.sh
  crontab -e
  # Add the following line:
  0 * * * * /home/pi/service_maintenance.sh >> /home/pi/service_maintenance.log 2>&1
  ```
