# ==============================================================================
# 🔧 HomeLab Hardhat Development Container
# ==============================================================================
# Smart contract development environment with:
#   - Hardhat 3.x + Foundry
#   - Base network configurations
#   - TypeScript + Solidity
#   - OpenZeppelin contracts
# ==============================================================================

FROM node:20-slim

LABEL maintainer="HomeLab <homelab@local>"
LABEL description="Hardhat + Foundry development environment for Base L2"
LABEL version="1.0.0"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    ~/.foundry/bin/foundryup

# Add Foundry to PATH
ENV PATH="/root/.foundry/bin:${PATH}"

# Install global npm packages
RUN npm install -g \
    pnpm \
    hardhat \
    ts-node \
    typescript \
    solhint \
    prettier \
    prettier-plugin-solidity

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install

# Copy project files
COPY . .

# Compile contracts
RUN pnpm compile 2>/dev/null || true

# Expose ports
# 8545 - Local node (Hardhat/Anvil)
# 8546 - WebSocket
EXPOSE 8545 8546

# Default command
CMD ["pnpm", "node"]
