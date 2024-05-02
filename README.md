
# Raspberry Pi Services Installation and Maintenance

## Overview
This document provides an overview and usage instructions for a bash script designed to install and maintain several key services on a Raspberry Pi. The services covered include Home Assistant, Pi-hole, Plex Media Server, Mumble Server, and Deluge with a Web UI. The script automates the installation and setup of these services and provides a maintenance routine to ensure they run smoothly.

## Installation Script
The provided script handles everything from updating the system, installing necessary packages, to configuring each service. It is designed to run with minimal user input beyond the initial launch.

## Running the Script
1. **Download the script**: Transfer the script to your Raspberry Pi.
   ```bash
   curl -o install_services.sh https://raw.githubusercontent.com/battlefeel1942/pi-home/main/install_services.sh
   ```
   ```bash
   curl -o maintain_services.sh https://raw.githubusercontent.com/battlefeel1942/pi-home/main/maintain_services.sh
   ```
3. **Set permissions**: Ensure the script is executable by running:
   ```bash
   chmod +x install_services.sh
   ```
   ```bash
   chmod +x maintain_services.sh
   ```
4. **Execute the script**: Start the installation by running:
   ```bash
   sudo chmod +x install_services.sh
   ```
5. **Follow prompts**: Some services like Pi-hole and Plex may require you to follow on-screen prompts to complete the installation.

## Maintenance Script
An additional maintenance script is included to automatically check and restart services if they are not running. This script also keeps your system up to date.

## Conclusion
Using these scripts, you can efficiently manage and maintain critical services on your Raspberry Pi, ensuring high availability and performance.


# Configuration Notes

## Pi-hole Configuration for Different Subnet
When Pi-hole is installed on a device that's on a different subnet from the clients (for instance, WireGuard clients on a different subnet), it's crucial to configure Pi-hole to respond correctly to DNS queries coming from those clients. Here's how you can set up Pi-hole to listen only on the `eth0` interface but still handle requests from another subnet:

### Step 1: Adjust Pi-hole's Listening Behavior
- Access the Pi-hole administrative dashboard via your web browser.
- Navigate to **Settings** and then to the **DNS** tab.
- Under the **Interface settings**, select **Respond only on interface eth0**. This setting ensures that Pi-hole binds to the `eth0` interface but will not restrict Pi-hole to respond only to requests from the subnet directly attached to `eth0`.
