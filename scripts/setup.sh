#!/bin/bash

# Minecraft Server Setup Script
# Description: Automates the installation of a Minecraft Server on Linux.
# Usage: ./setup.sh

set -euo pipefail # Exit on error, undefined variable, and pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration Variables (Adjustable)
SERVER_DIR="$HOME/minecraft-server"
JAVA_MEMORY="2G" # Amount of RAM to allocate, e.g., 2G, 4G
MC_USER="$USER"  # User to run the server as. Change if needed.

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root. Please run as a standard user with sudo privileges."
fi

# Check for required commands
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' is not installed. Please install it and run the script again."
    fi
}

log_info "Checking dependencies..."
check_dependency "sudo"
check_dependency "wget"
check_dependency "jq" # Required for parsing JSON to get the latest server jar

# Detect package manager and install the default/latest Java JDK
install_java() {
    log_info "Java JDK not found. Attempting to install the default/latest version..."
    if command -v apt &> /dev/null; then
        log_info "Detected apt (Debian/Ubuntu). Installing default-jdk..."
        sudo apt update -y
        sudo apt install -y default-jdk
    elif command -v dnf &> /dev/null; then
        log_info "Detected dnf (Fedora/RHEL). Installing java-latest-openjdk-devel..."
        sudo dnf install -y java-latest-openjdk-devel
    elif command -v pacman &> /dev/null; then
        log_info "Detected pacman (Arch). Installing jdk-openjdk..."
        sudo pacman -S --noconfirm jdk-openjdk
    elif command -v yum &> /dev/null; then
        log_info "Detected yum (older RHEL). Installing java-latest-openjdk-devel..."
        sudo yum install -y java-latest-openjdk-devel
    else
        log_error "Could not detect package manager. Please install a Java JDK manually and run the script again."
    fi

    # Verify installation
    if java -version &> /dev/null; then
        log_info "Java installed successfully."
        java -version
    else
        log_error "Java installation appears to have failed."
    fi
}

# Check if Java is already installed
if ! command -v java &> /dev/null; then
    install_java
else
    log_info "Java is already installed."
    java -version
fi

# Create server directory
log_info "Creating server directory at $SERVER_DIR..."
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR" || log_error "Failed to enter directory $SERVER_DIR"

# Download the latest Minecraft server.jar
log_info "Fetching the latest Minecraft server.jar download URL..."
JAR_URL=$(wget -qO- https://launchermeta.mojang.com/mc/game/version_manifest.json \
    | jq -r '.latest.release as $latest | .versions[] | select(.id == $latest) | .url' \
    | xargs wget -qO- \
    | jq -r '.downloads.server.url')

if [[ -z "$JAR_URL" ]]; then
    log_error "Failed to retrieve the server JAR URL. Please check your internet connection or try again later."
fi

log_info "Downloading the latest server.jar from Mojang..."
wget -O server.jar "$JAR_URL" || log_error "Failed to download server.jar"

# Agree to EULA
log_info "Starting server for the first time to generate EULA and other files..."
if ! java -Xms"$JAVA_MEMORY" -Xmx"$JAVA_MEMORY" -jar server.jar --nogui --initSettings > /dev/null 2>&1; then
    log_info "Expected initial startup failure (due to EULA). Proceeding..."
fi

if [[ ! -f "eula.txt" ]]; then
    log_error "eula.txt was not generated. Something went wrong with the initial startup."
fi

log_info "Accepting the Minecraft EULA..."
sed -i 's/eula=false/eula=true/g' eula.txt || log_error "Could not find or modify eula.txt."

# Create systemd service file
log_info "Creating a systemd service to manage the server..."

SERVICE_FILE="/etc/systemd/system/minecraft.service"
# Use sudo tee to write to a privileged file
sudo bash -c "cat > \"$SERVICE_FILE\" << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=$MC_USER
WorkingDirectory=$SERVER_DIR
ExecStart=/usr/bin/java -Xms$JAVA_MEMORY -Xmx$JAVA_MEMORY -jar server.jar --nogui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

if [[ ! -f "$SERVICE_FILE" ]]; then
    log_warn "Could not create the systemd service file. You may need to start the server manually."
else
    log_info "Reloading systemd and enabling the service..."
    sudo systemctl daemon-reload
    sudo systemctl enable minecraft.service

    # Final instructions
    log_info ""
    log_info "${GREEN}Setup complete!${NC}"
    log_info "Your Minecraft server is installed in: $SERVER_DIR"
    log_info "You can now configure your server by editing the files in that directory."
    log_info ""
    log_info "To start the server, run: ${YELLOW}sudo systemctl start minecraft${NC}"
    log_info "To stop the server, run: ${YELLOW}sudo systemctl stop minecraft${NC}"
    log_info "To view live logs, run: ${YELLOW}sudo journalctl -u minecraft -f${NC}"
fi

log_info "Don't forget to open port 25565 on your firewall if you want to play with others!"
