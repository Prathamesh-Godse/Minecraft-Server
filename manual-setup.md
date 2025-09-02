
# Manual Minecraft Server Setup Guide

This guide will help you set up a dedicated Minecraft: Java Edition server on a Linux machine (e.g., Ubuntu, Debian, Fedora, Arch). We'll cover installing Java, downloading the server files, and configuring it to run reliably in the background.

## Prerequisites

*   A Linux server or virtual private server (VPS).
*   SSH access to the server with `sudo` privileges.
*   A basic understanding of the command line.

---

## Step 1: Server Preparation & SSH

First, connect to your server via SSH.

```bash
ssh your_username@your_server_ip
```

## Step 2: Update Your System

It's always a good idea to start with an up-to-date system. Run the command for your distribution below.

**For Debian/Ubuntu:**
```bash
sudo apt update && sudo apt upgrade -y
```

**For Fedora:**
```bash
sudo dnf update -y
```

**For Arch Linux:**
```bash
sudo pacman -Syu --noconfirm
```

## Step 3: Install Java

Minecraft requires Java to run. You need to install a compatible version. We recommend using **Java 17** or **Java 21** (both are Long-Term Support versions).

Choose one of the following installation commands based on your distribution and preference.

### Option A: Install Java 17 (Stable)
**Debian/Ubuntu:**
```bash
sudo apt install openjdk-17-jre-headless -y
```
**Fedora:**
```bash
sudo dnf install java-17-openjdk-headless -y
```
**Arch Linux:**
```bash
sudo pacman -S jre17-openjdk-headless --noconfirm
```

### Option B: Install Java 21 (Latest LTS)
**Debian/Ubuntu:**
```bash
sudo apt install openjdk-21-jre-headless -y
```
**Fedora:**
```bash
sudo dnf install java-21-openjdk-headless -y
```
**Arch Linux:**
```bash
sudo pacman -S jre-openjdk-headless --noconfirm # Installs the latest stable (21)
```

### Verify Installation
Check that Java was installed correctly by checking its version.
```bash
java -version
# You should see output confirming your chosen version (e.g., openjdk 17.0.11 or 21.0.3)
```

## Step 4: Create the Server Directory

Let's create a dedicated folder for your Minecraft server to keep everything organized.

```bash
mkdir minecraft-server
cd minecraft-server
```

## Step 5: Download the Server Jar

Now, download the official Minecraft server software from Mojang.

1.  **Get the Latest Jar URL:** Visit the [Official Minecraft Server Download Page](https://www.minecraft.net/en-us/download/server). Right-click on the "minecraft_server.X.X.X.jar" link and copy the address.
2.  **Use `wget`:** Back in your terminal, use `wget` with the URL you just copied. *(The example URL below will be outdated, so use the real one!)*

```bash
# REPLACE THIS URL WITH THE ONE YOU COPIED!
wget https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar

# Let's give it a simpler name
mv server.jar minecraft_server.jar
```

## Step 6: First Run & Accepting the EULA

The first time you run the server, it will generate necessary files but fail until you agree to the EULA.

```bash
# This command allocates 2GB of RAM. Adjust the -Xmx and -Xms values as needed.
java -Xmx2G -Xms2G -jar minecraft_server.jar nogui
```

After it runs and stops, you need to accept the [Minecraft EULA](https://www.minecraft.net/en-us/eula). Open the generated `eula.txt` file and change `false` to `true`.

```bash
nano eula.txt
```
```ini
# Change this line:
eula=true
```
Save and exit the file (`Ctrl+X`, then `Y`, then `Enter` if using nano).

## Step 7: (Optional) Server Configuration

You can configure your server by editing the `server.properties` file that was generated.

```bash
nano server.properties
```
Here are some common settings to adjust:
- `motd`: The description shown in the multiplayer server list.
- `difficulty`: peaceful, easy, normal, hard.
- `pvp`: true/false.
- `online-mode`: Set to `false` only if you want to allow connections from players without premium accounts (not recommended for security reasons).

## Step 8: Run as a System Service

Running the server in your SSH session is temporary. Let's create a **systemd service** to run it in the background, restart it if it crashes, and start it automatically on boot.

### 1. Create the Service File
```bash
sudo nano /etc/systemd/system/minecraft.service
```

### 2. Copy the Service Configuration
Paste the following configuration into the file. **You must change the `User` and path in `WorkingDirectory` to match your username and server folder path.**

```ini
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=your_username  # CHANGE THIS to your username
Type=simple
WorkingDirectory=/home/your_username/minecraft-server  # CHANGE THIS to your path
ExecStart=/usr/bin/java -Xmx2G -Xms2G -jar minecraft_server.jar nogui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 3. Enable and Start the Service
```bash
# Reload systemd to load the new service
sudo systemctl daemon-reload

# Start the Minecraft server
sudo systemctl start minecraft

# Enable it to start automatically on boot
sudo systemctl enable minecraft

# Check its status to ensure it's running
sudo systemctl status minecraft
```

### Viewing Logs
You can watch the server logs live, just like the in-game console, using this command:
```bash
sudo journalctl -u minecraft -f
```

## Step 9: Connect to Your Server

1.  **Configure your firewall** to allow traffic on TCP port `25565`.
2.  **If you are on a home network,** configure **port forwarding** on your router for port `25565` to point to your server's local IP.
3.  In Minecraft, go to **Multiplayer** > **Add Server** and enter your server's public IP address.

---

## Contributing
Found an issue or have a suggestion for improving this guide? Feel free to open an Issue or submit a Pull Request!

## License
This project is licensed under the MIT License.
