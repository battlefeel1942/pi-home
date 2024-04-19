# System Initialization and Service Management Script

This Bash script automates the setup and maintenance of various services on a Linux system, specifically tailored for environments that utilize Docker. It ensures system updates, configures SSH, manages Docker installations, and sets up various Docker-based services like Samba, Pi-hole, OpenVPN, and more.

## Features

- **Automated updates**: Keeps the system up to date with the latest packages.
- **Secure credential storage**: Manages credentials for Pushbullet and Samba securely.
- **Service management**: Checks, runs, and updates several Docker services.
- **Notification system**: Sends notifications via Pushbullet when Docker containers are updated or restarted.
- **Cron automation**: Configures cron jobs to run this script at reboot and daily at 4 AM.

## Prerequisites

- Linux system with `bash` shell.
- `curl` or `wget` for script operations.
- `docker` and `docker-compose` should be installed.
- `sudo` privileges for installing packages, managing system services, and Docker management.

## Setup

### 1. Clone the Repository

Clone the repository or download the script directly to your local system using:

\`\`\`bash
wget https://raw.githubusercontent.com/yourusername/yourrepository/main/startup.sh
# Or use curl
curl -o startup.sh https://raw.githubusercontent.com/yourusername/yourrepository/main/startup.sh
\`\`\`

### 2. Make the Script Executable

Before running the script, change its permissions to make it executable:

\`\`\`bash
chmod +x startup.sh
\`\`\`

### 3. Run the Script

Execute the script with administrative privileges to perform all setup tasks:

\`\`\`bash
sudo ./startup.sh
\`\`\`

## Configuration

- **Pushbullet Integration**: The script prompts for your Pushbullet access token if it's not already saved.
- **Samba Configuration**: Prompts for Samba credentials on first run and saves them securely.
- **Docker Services**: Automatically manages the Docker services listed in the `docker-compose.yml` which it creates and maintains.

## Docker Services Managed

- **Samba**: Provides file sharing across different operating systems over a network.
- **Pi-hole**: Network-wide ad blocking.
- **OpenVPN**: Full-featured open source SSL VPN solution.
- **Plex**: Media server.
- **Mumble**: Low-latency, high-quality voice chat software for gaming.
- **Deluge**: Lightweight, Free Software, cross-platform BitTorrent client.
- **xTeVe**: IPTV for Plex DVR.
- **Home Assistant**: Open source home automation.
- **Ubuntu Desktop**: Web-accessible desktop environment.

Each service is checked and will only be installed or updated if necessary, ensuring minimal disruption and efficient use of resources.

## Security

This script involves substantial system modifications and as such should be run with an understanding of its impact. It modifies system services, installs new software, and changes permissions on directories.

Please review each operation within this script to ensure it aligns with your security policies and system configuration.

## Contribution

Contributions to this script are welcome. Please fork the repository and submit pull requests with your proposed changes.
