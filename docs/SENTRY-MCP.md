# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 SENTRY MCP SERVER
# Model Context Protocol Integration for Sentry
# ═══════════════════════════════════════════════════════════════════════════════

## Overview

The Sentry MCP server enables AI coding assistants (Claude, Cursor, VS Code Copilot)
to interact with Sentry for debugging and error analysis.

**Repository:** https://github.com/getsentry/sentry-mcp  
**Category:** DevTools / Debugging  
**Transport:** Stdio (local) or HTTP/SSE (remote)

## 🚀 Quick Start

### Option 1: Use Sentry's Hosted Service (Recommended)

Connect directly to Sentry's production MCP server:

```
https://mcp.sentry.dev/mcp
```

### Option 2: Local Stdio Mode

Run locally with your Sentry access token:

```bash
# Install and run
npx @sentry/mcp-server@latest --access-token=YOUR_SENTRY_TOKEN

# Or with environment variable
export SENTRY_ACCESS_TOKEN=your-token
npx @sentry/mcp-server@latest
```

### Option 3: Docker (home.lab)

```bash
cd c:\home.lab
docker compose -f docker/docker-compose.sentry-mcp.yml --profile sentry up -d
```

## 📋 Configuration

### VS Code / Copilot

Add to `.vscode/settings.json`:

```json
{
    "mcp": {
        "servers": {
            "sentry": {
                "command": "npx",
                "args": ["@sentry/mcp-server@latest"],
                "env": {
                    "SENTRY_ACCESS_TOKEN": "${env:SENTRY_ACCESS_TOKEN}"
                }
            }
        }
    }
}
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
    "mcpServers": {
        "sentry": {
            "command": "npx",
            "args": ["@sentry/mcp-server@latest", "--access-token", "YOUR_TOKEN"]
        }
    }
}
```

### Claude Desktop

Add to Claude's MCP configuration:

```json
{
    "mcpServers": {
        "sentry": {
            "command": "npx",
            "args": ["@sentry/mcp-server@latest"],
            "env": {
                "SENTRY_ACCESS_TOKEN": "your-token"
            }
        }
    }
}
```

## 🔑 Getting Your Sentry Access Token

1. Go to https://sentry.io/settings/account/api/auth-tokens/
2. Click "Create New Token"
3. Select these scopes:
   - `org:read`
   - `project:read`
   - `project:write`
   - `team:read`
   - `team:write`
   - `event:write`
4. Copy the token

### Self-Hosted Sentry

For self-hosted Sentry, add the `--host` flag:

```bash
npx @sentry/mcp-server@latest --access-token=TOKEN --host=sentry.example.com
```

## 🛠️ Available Tools

| Tool | Description |
|------|-------------|
| `list_organizations` | List accessible organizations |
| `list_projects` | List projects in an organization |
| `list_issues` | List issues/errors in a project |
| `get_issue` | Get detailed issue information |
| `search_events` | AI-powered event search (requires OpenAI key) |
| `search_issues` | AI-powered issue search (requires OpenAI key) |
| `resolve_issue` | Mark an issue as resolved |
| `ignore_issue` | Ignore an issue |

## ⚠️ AI-Powered Search

The `search_events` and `search_issues` tools use OpenAI to translate natural
language queries into Sentry's query syntax. To enable these:

```bash
export OPENAI_API_KEY=your-openai-key
npx @sentry/mcp-server@latest --access-token=TOKEN
```

Without the OpenAI key, these tools will be unavailable but all other tools
will work normally.

## 🐛 Troubleshooting

### "Error connecting to localhost:4894/stream"

This error means VS Code is trying to connect to a Sentry MCP server that isn't running.

**Solutions:**

1. **Start the local server:**
   ```bash
   npx @sentry/mcp-server@latest --access-token=YOUR_TOKEN
   ```

2. **Use the remote server instead:**
   Update your MCP config to use `https://mcp.sentry.dev/mcp`

3. **Disable if not needed:**
   Remove the Sentry MCP configuration from your settings

### "Authentication failed"

1. Check your access token is valid
2. Verify the token has the required scopes
3. For self-hosted, ensure the `--host` flag is set correctly

### "Tool not found"

Some tools require additional setup:
- AI search tools need `OPENAI_API_KEY`
- Some tools require specific Sentry plan features

## 📚 References

- [Sentry MCP GitHub](https://github.com/getsentry/sentry-mcp)
- [MCP Specification](https://modelcontextprotocol.io)
- [Sentry API Docs](https://docs.sentry.io/api/)
- [Sentry Access Tokens](https://sentry.io/settings/account/api/auth-tokens/)
