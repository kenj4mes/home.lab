#!/bin/bash
# ==============================================================================
# 🏠 Home Assistant Installation Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Two installation options:
#   1. Docker container (on existing VM)
#   2. Raspberry Pi OS image (dedicated device)
#
# Usage:
#   chmod +x install-homeassistant.sh
#   sudo ./install-homeassistant.sh
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     🏠 Home Assistant Installation                            ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# INSTALLATION OPTIONS
# ==============================================================================

echo -e "${YELLOW}📋 Installation Options:${NC}"
echo ""
echo "  1. Docker Container (on this machine)"
echo "     - Runs alongside other containers"
echo "     - Easy to backup and update"
echo "     - Some add-ons may not work"
echo ""
echo "  2. Raspberry Pi Instructions"
echo "     - Dedicated device for HA"
echo "     - Full add-on support"
echo "     - Recommended for serious use"
echo ""

read -p "Choose installation method (1 or 2): " method

case $method in
    1)
        # ==============================================================================
        # DOCKER INSTALLATION
        # ==============================================================================
        
        echo -e "\n${BLUE}🐳 Installing Home Assistant as Docker container...${NC}"
        
        # Configuration
        HA_CONFIG_PATH="${HA_CONFIG_PATH:-/home/$SUDO_USER/homeassistant}"
        
        # Create config directory
        mkdir -p "$HA_CONFIG_PATH"
        chown -R ${SUDO_UID:-1000}:${SUDO_GID:-1000} "$HA_CONFIG_PATH"
        
        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            echo -e "${RED}❌ Docker is not installed. Run install-docker.sh first.${NC}"
            exit 1
        fi
        
        # Stop existing container if running
        docker stop homeassistant 2>/dev/null || true
        docker rm homeassistant 2>/dev/null || true
        
        # Run Home Assistant container
        docker run -d \
            --name homeassistant \
            --privileged \
            --restart=unless-stopped \
            -e TZ=${TZ:-America/New_York} \
            -v "$HA_CONFIG_PATH":/config \
            -v /run/dbus:/run/dbus:ro \
            --network=host \
            ghcr.io/home-assistant/home-assistant:stable
        
        echo -e "${GREEN}✅ Home Assistant container started${NC}"
        
        # Wait for HA to initialize
        echo -e "\n${BLUE}⏳ Waiting for Home Assistant to initialize (30 seconds)...${NC}"
        sleep 30
        
        # Check status
        if docker ps | grep -q homeassistant; then
            echo -e "${GREEN}✅ Home Assistant is running!${NC}"
        else
            echo -e "${RED}❌ Home Assistant failed to start. Check logs:${NC}"
            echo "  docker logs homeassistant"
            exit 1
        fi
        
        # Get IP
        IP=$(hostname -I | awk '{print $1}')
        
        echo -e "\n${GREEN}"
        echo "╔══════════════════════════════════════════════════════════════════════════════╗"
        echo "║                     ✅ Home Assistant Installed!                              ║"
        echo "╚══════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${YELLOW}📋 Access:${NC}"
        echo "  URL:    http://${IP}:8123"
        echo "  Config: ${HA_CONFIG_PATH}"
        echo ""
        echo -e "${YELLOW}📋 Commands:${NC}"
        echo "  Logs:   docker logs -f homeassistant"
        echo "  Stop:   docker stop homeassistant"
        echo "  Start:  docker start homeassistant"
        echo "  Update: docker pull ghcr.io/home-assistant/home-assistant:stable && docker restart homeassistant"
        ;;
        
    2)
        # ==============================================================================
        # RASPBERRY PI INSTRUCTIONS
        # ==============================================================================
        
        echo -e "\n${BLUE}🍓 Raspberry Pi Installation Instructions${NC}"
        echo ""
        echo -e "${YELLOW}Step 1: Download Home Assistant OS${NC}"
        echo "  URL: https://www.home-assistant.io/installation/raspberrypi"
        echo "  Download the image for your Pi model (Pi 4 or Pi 5)"
        echo ""
        
        echo -e "${YELLOW}Step 2: Flash the image${NC}"
        echo "  1. Download Raspberry Pi Imager: https://www.raspberrypi.com/software/"
        echo "  2. Insert your SD card or SSD"
        echo "  3. Open Raspberry Pi Imager"
        echo "  4. Click 'Choose OS' → 'Use custom' → Select the HA OS image"
        echo "  5. Click 'Choose Storage' → Select your SD card/SSD"
        echo "  6. Click 'Write'"
        echo ""
        
        echo -e "${YELLOW}Step 3: Configure network (optional for WiFi)${NC}"
        echo "  If using WiFi, before first boot:"
        echo "  1. Mount the boot partition"
        echo "  2. Create 'CONFIG/network/my-network' file with content:"
        echo ""
        echo '  [connection]'
        echo '  id=my-network'
        echo '  uuid=<generate-a-uuid>'
        echo '  type=802-11-wireless'
        echo ''
        echo '  [802-11-wireless]'
        echo '  mode=infrastructure'
        echo '  ssid=YOUR_WIFI_SSID'
        echo ''
        echo '  [802-11-wireless-security]'
        echo '  auth-alg=open'
        echo '  key-mgmt=wpa-psk'
        echo '  psk=YOUR_WIFI_PASSWORD'
        echo ''
        echo '  [ipv4]'
        echo '  method=auto'
        echo ''
        echo '  [ipv6]'
        echo '  method=auto'
        echo ""
        
        echo -e "${YELLOW}Step 4: First boot${NC}"
        echo "  1. Insert the SD card/SSD into your Pi"
        echo "  2. Connect Ethernet (recommended) and power"
        echo "  3. Wait 5-10 minutes for initial setup"
        echo "  4. Access: http://homeassistant.local:8123"
        echo "     (or find IP in your router's DHCP list)"
        echo ""
        
        echo -e "${YELLOW}Step 5: Onboarding${NC}"
        echo "  1. Create your account"
        echo "  2. Set your location and preferences"
        echo "  3. Discover devices on your network"
        echo "  4. Install integrations for your smart devices"
        echo ""
        
        echo -e "${GREEN}📋 Recommended Add-ons:${NC}"
        echo "  - File Editor       - Edit config files in browser"
        echo "  - Terminal & SSH    - SSH access to HA"
        echo "  - Samba share       - Access config via network share"
        echo "  - MQTT Broker       - For IoT devices"
        echo "  - Node-RED          - Visual automation flows"
        echo "  - HACS              - Community add-ons store"
        echo ""
        ;;
        
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac
