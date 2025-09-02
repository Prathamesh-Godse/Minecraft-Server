#!/bin/bash
set -euo pipefail

# Function to download the latest server.jar
download_server() {
    echo "Fetching the latest Minecraft server.jar download URL..."
    JAR_URL=$(wget -qO- https://launchermeta.mojang.com/mc/game/version_manifest.json \
        | jq -r '.latest.release as $latest | .versions[] | select(.id == $latest) | .url' \
        | xargs wget -qO- \
        | jq -r '.downloads.server.url')

    echo "Downloading the latest server.jar from Mojang..."
    wget -O server.jar "$JAR_URL"
}

# If server.jar doesn't exist, download it
if [[ ! -f server.jar ]]; then
    download_server
fi

# If eula.txt doesn't exist, generate it and accept automatically
if [[ ! -f eula.txt ]]; then
    echo "Generating EULA file..."
    java -jar server.jar --initSettings > /dev/null 2>&1 || true
    echo "Accepting the Minecraft EULA..."
    sed -i 's/eula=false/eula=true/g' eula.txt
fi

# Start the server
echo "Starting Minecraft server with JVM options: ${JVM_OPTS}"
exec java ${JVM_OPTS} -jar server.jar --nogui
