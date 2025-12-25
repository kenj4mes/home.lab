# 📱 HomeLab iOS/iPadOS Guide
## Self-Hosted Infrastructure Access for Apple Mobile Devices

> **Note:** iOS has strict sandboxing - you cannot run Docker or servers directly on iPhone/iPad.
> This guide helps you **access** your HomeLab from iOS devices.

---

## 🚀 Quick Access Options

### Option 1: Web Browser (Recommended)
Access all HomeLab web interfaces from Safari:

| Service | URL | Description |
|---------|-----|-------------|
| **Open WebUI** | `http://YOUR_SERVER:3000` | ChatGPT-like AI interface |
| **Jellyfin** | `http://YOUR_SERVER:8096` | Media streaming |
| **Grafana** | `http://YOUR_SERVER:3100` | Monitoring dashboards |
| **Portainer** | `http://YOUR_SERVER:9000` | Container management |
| **BookStack** | `http://YOUR_SERVER:8082` | Documentation wiki |

### Option 2: Native Apps (Best Experience)

| App | Purpose | App Store Link |
|-----|---------|----------------|
| **Jellyfin** | Media streaming | [Download](https://apps.apple.com/app/jellyfin-mobile/id1480192618) |
| **Kiwix** | Offline Wikipedia | [Download](https://apps.apple.com/app/kiwix/id997079563) |
| **Grafana** | Monitoring | [Download](https://apps.apple.com/app/grafana/id1506881617) |
| **Termius** | SSH access | [Download](https://apps.apple.com/app/termius-terminal-ssh-client/id549039908) |
| **Prompt 3** | SSH (premium) | [Download](https://apps.apple.com/app/prompt-3/id1594420480) |

---

## 📲 Recommended Setup

### 1. Jellyfin App (Media)
Stream your media library anywhere:
1. Download Jellyfin from App Store
2. Add server: `http://YOUR_SERVER:8096`
3. Login with your credentials
4. Enable offline downloads for travel

### 2. Kiwix App (Offline Knowledge)
Access Wikipedia without internet:
1. Download Kiwix from App Store
2. Download ZIM files within app:
   - Wikipedia (Simple English): ~500MB
   - Wikipedia (Full): ~90GB
   - Stack Overflow: ~5GB
3. All content available offline

### 3. SSH Access (Terminal)
Control your server remotely:
1. Download Termius (free) or Prompt 3 (paid)
2. Add your server connection
3. Use key-based authentication for security
4. Run HomeLab commands:
   ```bash
   cd ~/homelab
   docker compose ps
   ollama list
   ```

### 4. Open WebUI (AI Chat)
Best AI experience on iOS:
1. Open Safari → `http://YOUR_SERVER:3000`
2. Tap Share → "Add to Home Screen"
3. Now it works like a native app!
4. Chat with local AI models

---

## 🔒 Secure Remote Access

To access HomeLab outside your home network:

### Option A: Tailscale (Recommended)
Free, secure VPN mesh network:
1. Install Tailscale on your server
2. Install Tailscale on iPhone/iPad
3. Access HomeLab using Tailscale IPs
4. No port forwarding needed!

```bash
# On your server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Option B: Cloudflare Tunnel
Expose services securely:
1. Create free Cloudflare account
2. Install cloudflared on server
3. Create tunnel to your services
4. Access via `https://yourservice.yourdomain.com`

### Option C: WireGuard VPN
Self-hosted VPN:
1. Set up WireGuard on your server
2. Install WireGuard app on iOS
3. Import configuration QR code
4. Connect to access all services

---

## 📱 iOS Shortcuts Integration

Create Siri shortcuts for quick access:

### "Start AI Chat" Shortcut
1. Open Shortcuts app
2. Create new shortcut
3. Add "Open URL" action
4. URL: `http://YOUR_SERVER:3000`
5. Name it "AI Chat"
6. Say "Hey Siri, AI Chat"

### "Check Server Status" Shortcut
1. Create new shortcut
2. Add "Run SSH Script" (via Termius)
3. Script: `docker compose ps`
4. Get push notification with results

---

## 🎬 Jellyfin Offline Sync

Watch media without internet:

1. Open Jellyfin app
2. Browse to movie/show
3. Tap download icon
4. Select quality (lower = smaller)
5. Content syncs in background
6. Available in Downloads tab

**Tip:** Enable "Sync on WiFi Only" to save mobile data.

---

## 🔋 Battery Optimization

Tips for using HomeLab apps on iOS:

1. **Background Refresh:** Enable for Jellyfin to sync downloads
2. **Low Power Mode:** Disable when streaming
3. **WiFi:** Prefer WiFi over cellular for large transfers
4. **Safari PWA:** Add Open WebUI to home screen (uses less battery than Safari tabs)

---

## ⚠️ Limitations

What you **cannot** do on iOS:
- ❌ Run Docker containers
- ❌ Run Ollama locally (no ARM iOS build)
- ❌ Host servers
- ❌ Install arbitrary Linux packages

What you **can** do:
- ✅ Access all HomeLab web interfaces
- ✅ Stream media via Jellyfin
- ✅ Chat with AI via Open WebUI
- ✅ SSH into your server
- ✅ Read offline Wikipedia via Kiwix
- ✅ Monitor with Grafana app
- ✅ Manage containers via Portainer web

---

## 🍎 iPad-Specific Features

iPadOS offers enhanced capabilities:

### Split View
Run Jellyfin + Safari side-by-side:
1. Open Jellyfin
2. Swipe up for dock
3. Drag Safari to screen edge
4. Watch video while chatting with AI

### Stage Manager (M1/M2 iPads)
Multiple floating windows:
- Jellyfin + Open WebUI + Termius
- True multitasking experience

### External Monitor
Connect iPad to monitor:
- Full-screen dashboards (Grafana)
- Extended workspace
- Use iPad as controller

---

## 📞 Troubleshooting

### Can't Connect to Server
1. Verify server IP: `hostname -I` on server
2. Check firewall: `sudo ufw status`
3. Ensure Docker is running: `docker ps`
4. Try ping from iOS: use Network Analyzer app

### Jellyfin Won't Stream
1. Check transcoding is enabled
2. Reduce stream quality
3. Verify sufficient server CPU
4. Check network bandwidth

### SSH Connection Refused
1. Enable SSH on server: `sudo systemctl enable ssh`
2. Check port 22 is open
3. Verify username/password
4. Try key-based auth

---

## 📚 More Resources

- [Tailscale iOS Guide](https://tailscale.com/kb/1020/install-ios)
- [Jellyfin iOS Docs](https://jellyfin.org/docs/general/clients/ios.html)
- [Kiwix iOS Help](https://www.kiwix.org/en/help/)
- [WireGuard iOS Setup](https://www.wireguard.com/install/)

---

*HomeLab - Access your sovereign infrastructure from anywhere* 🏠📱
