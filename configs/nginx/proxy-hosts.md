# Nginx Proxy Manager - Reverse Proxy Configurations
# ==============================================================================
#
# This file documents the proxy host configurations to create in NPM.
# Create these via the Nginx Proxy Manager web UI at http://<IP>:81
#
# Default credentials: admin@example.com / changeme
# ==============================================================================

## 🎬 Jellyfin (Media Server)
# ==============================================================================
Domain Names: media.local, media.yourdomain.com
Scheme: http
Forward Hostname / IP: jellyfin
Forward Port: 8096
Websockets Support: ON
Block Common Exploits: ON

# Custom Nginx Configuration (Advanced tab):
# proxy_buffering off;


## 📥 qBittorrent (Downloads)
# ==============================================================================
Domain Names: downloads.local
Scheme: http
Forward Hostname / IP: qbittorrent
Forward Port: 8080
Block Common Exploits: ON

# Access Control (for security):
# Add password protection via "Access List"


## 📚 Kiwix (Offline Wikipedia)
# ==============================================================================
Domain Names: wiki.local
Scheme: http
Forward Hostname / IP: kiwix
Forward Port: 8081
Block Common Exploits: ON


## 📝 BookStack (Documentation)
# ==============================================================================
Domain Names: docs.local
Scheme: http
Forward Hostname / IP: bookstack
Forward Port: 80
Block Common Exploits: ON


## 🤖 Open WebUI (ChatGPT-like LLM Interface)
# ==============================================================================
Domain Names: ai.local
Scheme: http
Forward Hostname / IP: open-webui
Forward Port: 8080
Websockets Support: ON
Block Common Exploits: ON


## 📊 Portainer (Docker Management)
# ==============================================================================
Domain Names: portainer.local
Scheme: https
Forward Hostname / IP: portainer
Forward Port: 9443
Block Common Exploits: ON


## 🏠 Home Assistant
# ==============================================================================
Domain Names: home.local
Scheme: http
Forward Hostname / IP: 192.168.1.50  # Raspberry Pi IP
Forward Port: 8123
Websockets Support: ON
Block Common Exploits: ON

# Custom Nginx Configuration (required for HA):
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";


## 🎥 Radarr (Movies)
# ==============================================================================
Domain Names: radarr.local
Scheme: http
Forward Hostname / IP: radarr
Forward Port: 7878
Block Common Exploits: ON


## 📺 Sonarr (TV)
# ==============================================================================
Domain Names: sonarr.local
Scheme: http
Forward Hostname / IP: sonarr
Forward Port: 8989
Block Common Exploits: ON


## 🎵 Lidarr (Music)
# ==============================================================================
Domain Names: lidarr.local
Scheme: http
Forward Hostname / IP: lidarr
Forward Port: 8686
Block Common Exploits: ON


## 🔍 Prowlarr (Indexers)
# ==============================================================================
Domain Names: prowlarr.local
Scheme: http
Forward Hostname / IP: prowlarr
Forward Port: 9696
Block Common Exploits: ON


# ==============================================================================
# SSL CERTIFICATES
# ==============================================================================
#
# For local domain (.local):
#   - Use self-signed certificates
#   - Or install mkcert on your machines
#
# For public domain:
#   1. Point DNS A record to your public IP
#   2. Forward ports 80 and 443 to Docker host
#   3. Enable "Force SSL" in proxy host
#   4. Request Let's Encrypt certificate in SSL tab
#
# To create a wildcard certificate:
#   1. Go to SSL Certificates
#   2. Add Let's Encrypt Certificate
#   3. Domain Names: *.yourdomain.com, yourdomain.com
#   4. Use DNS Challenge (required for wildcard)
#   5. Select your DNS provider and add credentials
# ==============================================================================


# ==============================================================================
# ACCESS LISTS (Security)
# ==============================================================================
#
# Create access lists for services that should be restricted:
#
# Name: LocalOnly
# Authorization:
#   - Satisfy Any
#   - Pass Auth to Host: ON
# Access:
#   - Allow: 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12
#   - Deny: all
#
# Apply to sensitive services like qBittorrent, Portainer, *Arr apps
# ==============================================================================
