# Update the package list, install curl if not installed, and download the script
sudo apt-get update && sudo apt-get install -y curl
curl -o startup.sh https://raw.githubusercontent.com/battlefeel1942/pi-home/main/startup.sh

### OR Update the package list, install wget if not installed, and download the script
sudo apt-get update && sudo apt-get install -y wget
wget -O startup.sh https://raw.githubusercontent.com/battlefeel1942/pi-home/main/startup.sh

# Make the script executable
chmod +x startup.sh

# Run the script
./startup.sh
