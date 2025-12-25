# ==============================================================================
# 💳 x402 Gateway - HTTP Payment Gateway
# ==============================================================================
# TypeScript/Node.js service for HTTP 402 payment handling
# ==============================================================================

FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm install

# Copy source
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# ==============================================================================
# Production Stage
# ==============================================================================
FROM node:20-alpine

WORKDIR /app

# Install wget for health check
RUN apk add --no-cache wget

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --spider -q http://localhost:3402/health || exit 1

EXPOSE 3402

CMD ["node", "dist/index.js"]
