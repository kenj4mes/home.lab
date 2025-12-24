#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
🔌 home.lab - Webhook Handler
Processes incoming and outgoing webhooks
═══════════════════════════════════════════════════════════════
"""

import asyncio
import hashlib
import hmac
import json
import logging
from datetime import datetime
from typing import Any, Dict, Optional

import httpx
import yaml
from fastapi import BackgroundTasks, FastAPI, HTTPException, Header, Request
from pydantic import BaseModel

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
app = FastAPI(title="Webhook Handler", version="1.0.0")
logger = logging.getLogger("webhook-handler")

CONFIG_PATH = "/app/configs/webhooks.yaml"
config: Dict[str, Any] = {}

class WebhookPayload(BaseModel):
    """Generic webhook payload"""
    event: str
    data: Dict[str, Any]
    timestamp: Optional[str] = None

class OutgoingWebhook(BaseModel):
    """Outgoing webhook request"""
    target: str
    event: str
    data: Dict[str, Any]
    channel: Optional[str] = None

# ───────────────────────────────────────────────────────────────
# Lifecycle
# ───────────────────────────────────────────────────────────────
@app.on_event("startup")
async def startup():
    """Load configuration"""
    global config
    try:
        with open(CONFIG_PATH) as f:
            config = yaml.safe_load(f)
        logger.info("Webhook handler started")
    except Exception as e:
        logger.error(f"Failed to load config: {e}")
        config = {"outgoing": {}, "incoming": {}, "triggers": {}}

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "webhook-handler",
        "timestamp": datetime.utcnow().isoformat()
    }

# ───────────────────────────────────────────────────────────────
# Signature Verification
# ───────────────────────────────────────────────────────────────
def verify_github_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify GitHub webhook signature"""
    expected = "sha256=" + hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)

def verify_generic_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify generic HMAC signature"""
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)

# ───────────────────────────────────────────────────────────────
# Incoming Webhooks
# ───────────────────────────────────────────────────────────────
@app.post("/webhooks/github")
async def github_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_hub_signature_256: str = Header(None),
    x_github_event: str = Header(None)
):
    """Handle GitHub webhooks"""
    import os
    
    payload = await request.body()
    secret = os.getenv("GITHUB_WEBHOOK_SECRET", "")
    
    if secret and x_hub_signature_256:
        if not verify_github_signature(payload, x_hub_signature_256, secret):
            raise HTTPException(status_code=401, detail="Invalid signature")
    
    data = json.loads(payload)
    
    # Log event
    logger.info(f"GitHub webhook: {x_github_event}")
    
    # Trigger actions based on event
    github_config = config.get("incoming", {}).get("github", {})
    actions = github_config.get("actions", {}).get(x_github_event, [])
    
    for action in actions:
        trigger_name = action.get("trigger")
        branch_filter = action.get("branch")
        
        # Check branch filter if present
        if branch_filter:
            ref = data.get("ref", "")
            if not ref.endswith(f"/{branch_filter}"):
                continue
        
        background_tasks.add_task(execute_trigger, trigger_name, data)
    
    return {"status": "received", "event": x_github_event}

@app.post("/webhooks/docker-hub")
async def dockerhub_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """Handle Docker Hub webhooks"""
    payload = await request.json()
    
    logger.info(f"Docker Hub webhook: {payload.get('repository', {}).get('name')}")
    
    # Trigger actions
    dockerhub_config = config.get("incoming", {}).get("docker_hub", {})
    for action in dockerhub_config.get("actions", []):
        trigger_name = action.get("trigger")
        background_tasks.add_task(execute_trigger, trigger_name, payload)
    
    return {"status": "received"}

@app.post("/webhooks/custom/{endpoint}")
async def custom_webhook(
    endpoint: str,
    request: Request,
    background_tasks: BackgroundTasks,
    authorization: str = Header(None)
):
    """Handle custom webhooks"""
    custom_config = config.get("incoming", {}).get("custom", {})
    endpoints = custom_config.get("endpoints", {})
    
    endpoint_path = f"/webhooks/{endpoint}"
    if endpoint_path not in endpoints:
        raise HTTPException(status_code=404, detail="Endpoint not found")
    
    endpoint_config = endpoints[endpoint_path]
    
    # Simple auth check
    if endpoint_config.get("auth") == "bearer_token" and not authorization:
        raise HTTPException(status_code=401, detail="Authorization required")
    
    payload = await request.json()
    
    for action in endpoint_config.get("actions", []):
        trigger_name = action.get("trigger")
        background_tasks.add_task(execute_trigger, trigger_name, payload)
    
    return {"status": "received", "endpoint": endpoint}

# ───────────────────────────────────────────────────────────────
# Outgoing Webhooks
# ───────────────────────────────────────────────────────────────
@app.post("/send")
async def send_webhook(webhook: OutgoingWebhook):
    """Send outgoing webhook"""
    target = webhook.target.lower()
    
    if target == "slack":
        return await send_slack(webhook)
    elif target == "discord":
        return await send_discord(webhook)
    else:
        raise HTTPException(status_code=400, detail=f"Unknown target: {target}")

async def send_slack(webhook: OutgoingWebhook) -> Dict:
    """Send Slack notification"""
    import os
    
    slack_config = config.get("outgoing", {}).get("slack", {})
    if not slack_config.get("enabled"):
        return {"status": "skipped", "reason": "Slack disabled"}
    
    url = os.getenv("SLACK_WEBHOOK_URL")
    if not url:
        return {"status": "skipped", "reason": "No Slack URL configured"}
    
    # Get template
    templates = slack_config.get("templates", {})
    template = templates.get(webhook.event, {})
    
    # Build message
    message = {
        "channel": webhook.channel or slack_config.get("channels", {}).get("default", "#homelab"),
        "attachments": [{
            "color": template.get("color", "#36a64f"),
            "title": format_template(template.get("title", webhook.event), webhook.data),
            "fields": [
                {
                    "title": field.get("title"),
                    "value": format_template(field.get("value", ""), webhook.data),
                    "short": True
                }
                for field in template.get("fields", [])
            ],
            "ts": datetime.utcnow().timestamp()
        }]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=message)
            return {"status": "sent", "response": response.status_code}
    except Exception as e:
        logger.error(f"Failed to send Slack webhook: {e}")
        return {"status": "error", "error": str(e)}

async def send_discord(webhook: OutgoingWebhook) -> Dict:
    """Send Discord notification"""
    import os
    
    discord_config = config.get("outgoing", {}).get("discord", {})
    if not discord_config.get("enabled"):
        return {"status": "skipped", "reason": "Discord disabled"}
    
    url = os.getenv("DISCORD_WEBHOOK_URL")
    if not url:
        return {"status": "skipped", "reason": "No Discord URL configured"}
    
    message = {
        "content": f"**{webhook.event}**",
        "embeds": [{
            "title": webhook.event,
            "description": json.dumps(webhook.data, indent=2)[:2000],
            "timestamp": datetime.utcnow().isoformat()
        }]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=message)
            return {"status": "sent", "response": response.status_code}
    except Exception as e:
        logger.error(f"Failed to send Discord webhook: {e}")
        return {"status": "error", "error": str(e)}

# ───────────────────────────────────────────────────────────────
# Trigger Execution
# ───────────────────────────────────────────────────────────────
async def execute_trigger(trigger_name: str, data: Dict):
    """Execute a configured trigger"""
    import subprocess
    
    triggers = config.get("triggers", {})
    trigger = triggers.get(trigger_name)
    
    if not trigger:
        logger.warning(f"Unknown trigger: {trigger_name}")
        return
    
    trigger_type = trigger.get("type")
    
    if trigger_type == "script":
        command = trigger.get("command")
        timeout = trigger.get("timeout", 300)
        
        try:
            result = subprocess.run(
                command.split(),
                capture_output=True,
                timeout=timeout
            )
            logger.info(f"Trigger {trigger_name} completed: {result.returncode}")
        except Exception as e:
            logger.error(f"Trigger {trigger_name} failed: {e}")
            
    elif trigger_type == "webhook":
        target = trigger.get("target")
        template = trigger.get("template")
        
        await send_webhook(OutgoingWebhook(
            target=target,
            event=template,
            data=data
        ))
        
    elif trigger_type == "docker":
        action = trigger.get("action")
        logger.info(f"Docker trigger: {action} (not implemented in handler)")

def format_template(template: str, data: Dict) -> str:
    """Simple template formatting"""
    result = template
    for key, value in data.items():
        result = result.replace(f"{{{{.{key}}}}}", str(value))
    return result

# ───────────────────────────────────────────────────────────────
# Stats
# ───────────────────────────────────────────────────────────────
@app.get("/stats")
async def stats():
    """Get webhook statistics"""
    return {
        "outgoing_enabled": {
            name: cfg.get("enabled", False)
            for name, cfg in config.get("outgoing", {}).items()
        },
        "incoming_enabled": {
            name: cfg.get("enabled", False)
            for name, cfg in config.get("incoming", {}).items()
        },
        "triggers_count": len(config.get("triggers", {}))
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5400)
