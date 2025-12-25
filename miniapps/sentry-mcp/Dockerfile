# ==============================================================================
# 🔍 Sentry MCP Server - Dockerfile
# ==============================================================================
# HTTP server for remote MCP connections
# ==============================================================================

FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Clone and build sentry-mcp
RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/getsentry/sentry-mcp.git . && \
    pnpm install --frozen-lockfile && \
    pnpm build

# Expose HTTP port
EXPOSE 5173

# Run the server
CMD ["pnpm", "dev"]
