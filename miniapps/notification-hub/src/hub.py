#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
🔔 home.lab - Notification Hub
Centralized notification routing and delivery
═══════════════════════════════════════════════════════════════
"""

import asyncio
import json
import os
from datetime import datetime
from typing import Any, Dict, List, Optional

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
app = FastAPI(title="Notification Hub", version="1.0.0")

class Notification(BaseModel):
    """Notification payload"""
    title: str
    message: str
    severity: str = "info"  # info, warning, error, critical
    source: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    channels: Optional[List[str]] = None  # If None, use default channels

class NotificationResult(BaseModel):
    """Result of notification delivery"""
    channel: str
    status: str
    error: Optional[str] = None

# Notification history
notification_history: List[Dict] = []
HISTORY_SIZE = 1000

# ───────────────────────────────────────────────────────────────
# Channel Configuration
# ───────────────────────────────────────────────────────────────
def get_channel_config():
    """Get channel configuration from environment"""
    return {
        "slack": {
            "enabled": bool(os.getenv("SLACK_WEBHOOK_URL")),
            "url": os.getenv("SLACK_WEBHOOK_URL"),
            "default_channel": "#homelab"
        },
        "discord": {
            "enabled": bool(os.getenv("DISCORD_WEBHOOK_URL")),
            "url": os.getenv("DISCORD_WEBHOOK_URL")
        },
        "email": {
            "enabled": bool(os.getenv("SMTP_HOST")),
            "host": os.getenv("SMTP_HOST"),
            "port": int(os.getenv("SMTP_PORT", "587")),
            "user": os.getenv("SMTP_USER"),
            "password": os.getenv("SMTP_PASSWORD"),
            "from_addr": os.getenv("SMTP_FROM", "homelab@localhost"),
            "to_addr": os.getenv("ADMIN_EMAIL")
        },
        "pushover": {
            "enabled": bool(os.getenv("PUSHOVER_TOKEN")),
            "token": os.getenv("PUSHOVER_TOKEN"),
            "user": os.getenv("PUSHOVER_USER")
        },
        "ntfy": {
            "enabled": bool(os.getenv("NTFY_URL")),
            "url": os.getenv("NTFY_URL", "https://ntfy.sh"),
            "topic": os.getenv("NTFY_TOPIC", "homelab")
        },
        "gotify": {
            "enabled": bool(os.getenv("GOTIFY_URL")),
            "url": os.getenv("GOTIFY_URL"),
            "token": os.getenv("GOTIFY_TOKEN")
        }
    }

# Severity to priority mapping
SEVERITY_PRIORITY = {
    "info": 1,
    "warning": 2,
    "error": 3,
    "critical": 4
}

# Severity to emoji
SEVERITY_EMOJI = {
    "info": "ℹ️",
    "warning": "⚠️",
    "error": "❌",
    "critical": "🚨"
}

# ───────────────────────────────────────────────────────────────
# Lifecycle
# ───────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    """Health check"""
    config = get_channel_config()
    enabled_channels = [k for k, v in config.items() if v.get("enabled")]
    
    return {
        "status": "healthy",
        "service": "notification-hub",
        "enabled_channels": enabled_channels,
        "pending_notifications": 0,
        "timestamp": datetime.utcnow().isoformat()
    }

# ───────────────────────────────────────────────────────────────
# Send Notifications
# ───────────────────────────────────────────────────────────────
@app.post("/notify")
async def send_notification(notification: Notification):
    """Send notification to configured channels"""
    config = get_channel_config()
    results = []
    
    # Determine channels
    if notification.channels:
        channels = notification.channels
    else:
        # Default: send to all enabled channels based on severity
        channels = [k for k, v in config.items() if v.get("enabled")]
        
        # For info, only send to slack/discord
        if notification.severity == "info":
            channels = [c for c in channels if c in ["slack", "discord", "ntfy"]]
    
    # Send to each channel
    for channel in channels:
        try:
            if channel == "slack":
                result = await send_slack(notification, config["slack"])
            elif channel == "discord":
                result = await send_discord(notification, config["discord"])
            elif channel == "email":
                result = await send_email(notification, config["email"])
            elif channel == "pushover":
                result = await send_pushover(notification, config["pushover"])
            elif channel == "ntfy":
                result = await send_ntfy(notification, config["ntfy"])
            elif channel == "gotify":
                result = await send_gotify(notification, config["gotify"])
            else:
                result = NotificationResult(channel=channel, status="unknown_channel")
                
            results.append(result)
        except Exception as e:
            results.append(NotificationResult(
                channel=channel,
                status="error",
                error=str(e)
            ))
    
    # Record in history
    record = {
        "id": f"notif_{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}",
        "notification": notification.dict(),
        "results": [r.dict() for r in results],
        "timestamp": datetime.utcnow().isoformat()
    }
    notification_history.append(record)
    
    # Trim history
    if len(notification_history) > HISTORY_SIZE:
        notification_history[:] = notification_history[-HISTORY_SIZE:]
    
    return {
        "status": "sent",
        "channels": len(results),
        "results": [r.dict() for r in results]
    }

# ───────────────────────────────────────────────────────────────
# Channel Handlers
# ───────────────────────────────────────────────────────────────
async def send_slack(notification: Notification, config: Dict) -> NotificationResult:
    """Send to Slack"""
    if not config.get("enabled"):
        return NotificationResult(channel="slack", status="disabled")
    
    emoji = SEVERITY_EMOJI.get(notification.severity, "ℹ️")
    color = {
        "info": "#36a64f",
        "warning": "#ff9800",
        "error": "#f44336",
        "critical": "#d32f2f"
    }.get(notification.severity, "#36a64f")
    
    payload = {
        "attachments": [{
            "color": color,
            "title": f"{emoji} {notification.title}",
            "text": notification.message,
            "fields": [
                {"title": "Severity", "value": notification.severity, "short": True},
                {"title": "Source", "value": notification.source or "unknown", "short": True}
            ],
            "ts": datetime.utcnow().timestamp()
        }]
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(config["url"], json=payload)
        
    return NotificationResult(
        channel="slack",
        status="sent" if response.status_code == 200 else "error",
        error=response.text if response.status_code != 200 else None
    )

async def send_discord(notification: Notification, config: Dict) -> NotificationResult:
    """Send to Discord"""
    if not config.get("enabled"):
        return NotificationResult(channel="discord", status="disabled")
    
    emoji = SEVERITY_EMOJI.get(notification.severity, "ℹ️")
    color = {
        "info": 0x36a64f,
        "warning": 0xff9800,
        "error": 0xf44336,
        "critical": 0xd32f2f
    }.get(notification.severity, 0x36a64f)
    
    payload = {
        "embeds": [{
            "title": f"{emoji} {notification.title}",
            "description": notification.message,
            "color": color,
            "fields": [
                {"name": "Severity", "value": notification.severity, "inline": True},
                {"name": "Source", "value": notification.source or "unknown", "inline": True}
            ],
            "timestamp": datetime.utcnow().isoformat()
        }]
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(config["url"], json=payload)
        
    return NotificationResult(
        channel="discord",
        status="sent" if response.status_code == 204 else "error",
        error=response.text if response.status_code != 204 else None
    )

async def send_email(notification: Notification, config: Dict) -> NotificationResult:
    """Send email"""
    if not config.get("enabled"):
        return NotificationResult(channel="email", status="disabled")
    
    import smtplib
    from email.mime.text import MIMEText
    
    try:
        emoji = SEVERITY_EMOJI.get(notification.severity, "")
        msg = MIMEText(f"{notification.message}\n\nSource: {notification.source or 'unknown'}")
        msg["Subject"] = f"{emoji} [{notification.severity.upper()}] {notification.title}"
        msg["From"] = config["from_addr"]
        msg["To"] = config["to_addr"]
        
        with smtplib.SMTP(config["host"], config["port"]) as server:
            server.starttls()
            if config.get("user") and config.get("password"):
                server.login(config["user"], config["password"])
            server.send_message(msg)
            
        return NotificationResult(channel="email", status="sent")
    except Exception as e:
        return NotificationResult(channel="email", status="error", error=str(e))

async def send_pushover(notification: Notification, config: Dict) -> NotificationResult:
    """Send to Pushover"""
    if not config.get("enabled"):
        return NotificationResult(channel="pushover", status="disabled")
    
    priority = SEVERITY_PRIORITY.get(notification.severity, 0)
    
    payload = {
        "token": config["token"],
        "user": config["user"],
        "title": notification.title,
        "message": notification.message,
        "priority": priority if priority < 3 else 1  # Pushover max is 2
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post("https://api.pushover.net/1/messages.json", data=payload)
        
    return NotificationResult(
        channel="pushover",
        status="sent" if response.status_code == 200 else "error",
        error=response.text if response.status_code != 200 else None
    )

async def send_ntfy(notification: Notification, config: Dict) -> NotificationResult:
    """Send to ntfy.sh"""
    if not config.get("enabled"):
        return NotificationResult(channel="ntfy", status="disabled")
    
    priority = SEVERITY_PRIORITY.get(notification.severity, 3)
    emoji = SEVERITY_EMOJI.get(notification.severity, "")
    
    url = f"{config['url']}/{config['topic']}"
    headers = {
        "Title": f"{emoji} {notification.title}",
        "Priority": str(priority),
        "Tags": notification.severity
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, content=notification.message, headers=headers)
        
    return NotificationResult(
        channel="ntfy",
        status="sent" if response.status_code == 200 else "error",
        error=response.text if response.status_code != 200 else None
    )

async def send_gotify(notification: Notification, config: Dict) -> NotificationResult:
    """Send to Gotify"""
    if not config.get("enabled"):
        return NotificationResult(channel="gotify", status="disabled")
    
    priority = SEVERITY_PRIORITY.get(notification.severity, 5)
    
    payload = {
        "title": notification.title,
        "message": notification.message,
        "priority": priority * 2  # Gotify uses 1-10
    }
    
    url = f"{config['url']}/message?token={config['token']}"
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        
    return NotificationResult(
        channel="gotify",
        status="sent" if response.status_code == 200 else "error",
        error=response.text if response.status_code != 200 else None
    )

# ───────────────────────────────────────────────────────────────
# History & Status
# ───────────────────────────────────────────────────────────────
@app.get("/history")
async def get_history(limit: int = 50):
    """Get notification history"""
    return {
        "notifications": notification_history[-limit:][::-1],
        "total": len(notification_history)
    }

@app.get("/channels")
async def get_channels():
    """Get channel status"""
    config = get_channel_config()
    return {
        "channels": {
            name: {"enabled": cfg.get("enabled", False)}
            for name, cfg in config.items()
        }
    }

@app.post("/test/{channel}")
async def test_channel(channel: str):
    """Test a notification channel"""
    test_notification = Notification(
        title="Test Notification",
        message="This is a test notification from home.lab",
        severity="info",
        source="notification-hub",
        channels=[channel]
    )
    return await send_notification(test_notification)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5502)
