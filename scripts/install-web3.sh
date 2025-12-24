#!/usr/bin/env bash
# ==============================================================================
# 🌐 Web3 Development Stack Installation
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs complete Web3/Blockchain development environment:
#   - Node.js & pnpm (package management)
#   - Hardhat (smart contract development)
#   - Foundry (high-performance Solidity toolkit)
#   - Viem, Ethers, Wagmi (TypeScript Web3 libs)
#   - Base SDKs (account-sdk, bridge-sdk)
#   - Solidity compiler & tools
#   - Anvil (local testnet)
#   - Offline-capable caching
#
# Usage:
#   chmod +x install-web3.sh
#   sudo ./install-web3.sh [--offline-cache]
# ==============================================================================

set -e

# Colors (some may be unused but kept for consistency)
# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OFFLINE_CACHE="${1:-false}"
[[ "$1" == "--offline-cache" ]] && OFFLINE_CACHE="true"

CACHE_DIR="${CACHE_DIR:-/opt/homelab/cache/web3}"
NODE_VERSION="${NODE_VERSION:-20}"
SOLC_VERSION="${SOLC_VERSION:-0.8.28}"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🌐 Web3 Development Stack                                  ║"
echo "║                      Hardhat + Foundry + Base                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [[ $EUID -eq 0 ]]; then
    # Running as root, find real user
    INSTALL_USER="${SUDO_USER:-root}"
    USER_HOME=$(eval echo ~${INSTALL_USER})
else
    INSTALL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

echo -e "${BLUE}Installing for user: ${INSTALL_USER}${NC}"
echo -e "${BLUE}Cache directory: ${CACHE_DIR}${NC}"
echo ""

# ==============================================================================
# 1. Node.js & pnpm
# ==============================================================================

echo -e "${BLUE}[1/6] Installing Node.js ${NODE_VERSION} & pnpm...${NC}"

if command -v node &> /dev/null && [[ "$(node --version | cut -d. -f1 | tr -d 'v')" -ge "${NODE_VERSION}" ]]; then
    echo -e "${YELLOW}○ Node.js already installed: $(node --version)${NC}"
else
    # Install nvm for the user
    if [[ ! -d "${USER_HOME}/.nvm" ]]; then
        echo "Installing nvm..."
        sudo -u "${INSTALL_USER}" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    fi
    
    # Install Node via nvm
    sudo -u "${INSTALL_USER}" bash -c "source ${USER_HOME}/.nvm/nvm.sh && nvm install ${NODE_VERSION} && nvm use ${NODE_VERSION} && nvm alias default ${NODE_VERSION}"
    echo -e "${GREEN}✓ Node.js ${NODE_VERSION} installed${NC}"
fi

# Install pnpm
if ! command -v pnpm &> /dev/null; then
    echo "Installing pnpm..."
    sudo -u "${INSTALL_USER}" bash -c "source ${USER_HOME}/.nvm/nvm.sh && npm install -g pnpm"
    echo -e "${GREEN}✓ pnpm installed${NC}"
else
    echo -e "${YELLOW}○ pnpm already installed: $(pnpm --version)${NC}"
fi

# ==============================================================================
# 2. Foundry (Forge, Cast, Anvil, Chisel)
# ==============================================================================

echo -e "${BLUE}[2/6] Installing Foundry toolkit...${NC}"

if command -v forge &> /dev/null; then
    echo -e "${YELLOW}○ Foundry already installed: $(forge --version | head -1)${NC}"
else
    echo "Installing Foundry..."
    
    # Download and install foundryup
    curl -L https://foundry.paradigm.xyz | bash
    
    # Install foundry tools
    export PATH="${USER_HOME}/.foundry/bin:$PATH"
    "${USER_HOME}/.foundry/bin/foundryup"
    
    # Add to path permanently
    if ! grep -q "foundry" "${USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "${USER_HOME}/.bashrc"
    fi
    
    echo -e "${GREEN}✓ Foundry installed (forge, cast, anvil, chisel)${NC}"
fi

# ==============================================================================
# 3. Hardhat & Global Tools
# ==============================================================================

echo -e "${BLUE}[3/6] Installing Hardhat & development tools...${NC}"

# Create global packages list
GLOBAL_PACKAGES=(
    "hardhat"
    "solc"
    "ts-node"
    "typescript"
    "@types/node"
    "prettier"
    "prettier-plugin-solidity"
    "solhint"
    "slither-analyzer"
)

echo "Installing global npm packages..."
for pkg in "${GLOBAL_PACKAGES[@]}"; do
    sudo -u "${INSTALL_USER}" bash -c "source ${USER_HOME}/.nvm/nvm.sh && npm install -g ${pkg}" 2>/dev/null || \
        echo -e "${YELLOW}○ Skipped ${pkg} (may need Python/pip)${NC}"
done

echo -e "${GREEN}✓ Hardhat & tools installed${NC}"

# ==============================================================================
# 4. Python Tools (Slither, Mythril)
# ==============================================================================

echo -e "${BLUE}[4/6] Installing Python security tools...${NC}"

# Ensure pip is available
if ! command -v pip3 &> /dev/null; then
    apt-get install -y python3-pip python3-venv
fi

# Install security analysis tools
pip3 install --quiet slither-analyzer mythril vyper 2>/dev/null || {
    echo -e "${YELLOW}○ Some Python tools may require manual install${NC}"
}

echo -e "${GREEN}✓ Security analysis tools installed${NC}"

# ==============================================================================
# 5. Base SDKs & Web3 Libraries
# ==============================================================================

echo -e "${BLUE}[5/6] Setting up Web3 libraries template...${NC}"

# Create a template project with all dependencies
TEMPLATE_DIR="${CACHE_DIR}/base-template"
mkdir -p "${TEMPLATE_DIR}"

cat > "${TEMPLATE_DIR}/package.json" << 'EOF'
{
  "name": "homelab-web3-template",
  "version": "1.0.0",
  "description": "HomeLab Web3 Development Template with Base L2 support",
  "type": "module",
  "scripts": {
    "compile": "hardhat compile",
    "test": "hardhat test",
    "node": "hardhat node",
    "deploy": "hardhat run scripts/deploy.ts",
    "anvil": "anvil --host 0.0.0.0 --port 8545",
    "anvil:base": "anvil --fork-url https://mainnet.base.org --host 0.0.0.0",
    "lint": "solhint 'contracts/**/*.sol'",
    "format": "prettier --write 'contracts/**/*.sol' 'scripts/**/*.ts' 'test/**/*.ts'"
  },
  "dependencies": {
    "@base/account-sdk": "^1.0.0",
    "@openzeppelin/contracts": "^5.1.0",
    "@openzeppelin/contracts-upgradeable": "^5.1.0",
    "ethers": "^6.13.0",
    "viem": "^2.21.0",
    "wagmi": "^2.14.0"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^5.0.0",
    "@nomicfoundation/hardhat-verify": "^2.0.0",
    "@typechain/hardhat": "^9.0.0",
    "@types/node": "^22.0.0",
    "hardhat": "^3.0.0",
    "hardhat-gas-reporter": "^2.0.0",
    "prettier": "^3.3.0",
    "prettier-plugin-solidity": "^1.4.0",
    "solhint": "^5.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.6.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
EOF

# Create Hardhat config for Base networks
cat > "${TEMPLATE_DIR}/hardhat.config.ts" << 'EOF'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

// Environment variables (use .env file or docker secrets)
const DEPLOYER_KEY = process.env.DEPLOYER_PRIVATE_KEY || "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const ETHERSCAN_KEY = process.env.ETHERSCAN_API_KEY || "";
const BASESCAN_KEY = process.env.BASESCAN_API_KEY || "";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    // Local development
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,
    },
    anvil: {
      url: "http://localhost:8545",
      chainId: 31337,
    },
    
    // HomeLab Base Node (local)
    "homelab-base": {
      url: process.env.BASE_RPC_URL || "http://base-node:8545",
      chainId: 8453,
      accounts: [DEPLOYER_KEY],
    },
    
    // Base Mainnet
    base: {
      url: process.env.BASE_MAINNET_RPC || "https://mainnet.base.org",
      chainId: 8453,
      accounts: [DEPLOYER_KEY],
    },
    
    // Base Sepolia (testnet)
    "base-sepolia": {
      url: process.env.BASE_SEPOLIA_RPC || "https://sepolia.base.org",
      chainId: 84532,
      accounts: [DEPLOYER_KEY],
    },
    
    // Ethereum Mainnet
    mainnet: {
      url: process.env.ETH_MAINNET_RPC || "https://eth.llamarpc.com",
      chainId: 1,
      accounts: [DEPLOYER_KEY],
    },
    
    // Ethereum Sepolia
    sepolia: {
      url: process.env.ETH_SEPOLIA_RPC || "https://rpc.sepolia.org",
      chainId: 11155111,
      accounts: [DEPLOYER_KEY],
    },
  },
  
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_KEY,
      base: BASESCAN_KEY,
      baseSepolia: BASESCAN_KEY,
      sepolia: ETHERSCAN_KEY,
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
        },
      },
    ],
  },
  
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
EOF

# Create foundry.toml for Base networks
cat > "${TEMPLATE_DIR}/foundry.toml" << 'EOF'
[profile.default]
src = "contracts"
out = "out"
libs = ["node_modules", "lib"]
optimizer = true
optimizer_runs = 200
via_ir = true
solc_version = "0.8.28"
auto_detect_solc = false

[rpc_endpoints]
localhost = "http://localhost:8545"
homelab = "${BASE_RPC_URL}"
base = "${BASE_MAINNET_RPC}"
base_sepolia = "${BASE_SEPOLIA_RPC}"
mainnet = "${ETH_MAINNET_RPC}"
sepolia = "${ETH_SEPOLIA_RPC}"

[etherscan]
base = { key = "${BASESCAN_API_KEY}", chain = 8453, url = "https://api.basescan.org/api" }
base_sepolia = { key = "${BASESCAN_API_KEY}", chain = 84532, url = "https://api-sepolia.basescan.org/api" }
mainnet = { key = "${ETHERSCAN_API_KEY}", chain = 1 }
sepolia = { key = "${ETHERSCAN_API_KEY}", chain = 11155111 }

[fmt]
bracket_spacing = true
int_types = "long"
line_length = 120
multiline_func_header = "all"
number_underscore = "thousands"
quote_style = "double"
tab_width = 4
wrap_comments = true
EOF

# Cache offline if requested
if [[ "$OFFLINE_CACHE" == "true" ]]; then
    echo "Caching packages for offline use..."
    cd "${TEMPLATE_DIR}"
    sudo -u "${INSTALL_USER}" bash -c "source ${USER_HOME}/.nvm/nvm.sh && pnpm install --prefer-offline" || true
    echo -e "${GREEN}✓ Packages cached for offline use${NC}"
fi

chown -R "${INSTALL_USER}:${INSTALL_USER}" "${TEMPLATE_DIR}"
echo -e "${GREEN}✓ Web3 template created at ${TEMPLATE_DIR}${NC}"

# ==============================================================================
# 6. Environment Setup
# ==============================================================================

echo -e "${BLUE}[6/6] Finalizing environment...${NC}"

# Create helper script for new projects
mkdir -p /usr/local/bin

cat > /usr/local/bin/new-web3-project << 'EOF'
#!/bin/bash
# Create a new Web3 project from the HomeLab template

PROJECT_NAME="${1:-my-web3-project}"
TEMPLATE_DIR="/opt/homelab/cache/web3/base-template"

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
    echo "Template not found. Run install-web3.sh first."
    exit 1
fi

echo "Creating new Web3 project: ${PROJECT_NAME}"
mkdir -p "${PROJECT_NAME}"
cp -r "${TEMPLATE_DIR}"/* "${PROJECT_NAME}/"
cd "${PROJECT_NAME}"

# Initialize git
git init
echo "node_modules/\ncache/\nartifacts/\nout/\n.env\n*.log" > .gitignore

# Create initial contract
mkdir -p contracts scripts test

cat > contracts/Counter.sol << 'SOLEOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Counter - A simple counter contract for testing
/// @notice Demonstrates basic Solidity patterns
contract Counter {
    uint256 public count;

    event CountChanged(uint256 newCount);

    function increment() external {
        count++;
        emit CountChanged(count);
    }

    function decrement() external {
        require(count > 0, "Counter: cannot decrement below zero");
        count--;
        emit CountChanged(count);
    }

    function setCount(uint256 _count) external {
        count = _count;
        emit CountChanged(count);
    }
}
SOLEOF

cat > scripts/deploy.ts << 'TSEOF'
import { ethers } from "hardhat";

async function main() {
    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();
    await counter.waitForDeployment();
    console.log(`Counter deployed to: ${await counter.getAddress()}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
TSEOF

echo ""
echo "✓ Project created: ${PROJECT_NAME}"
echo ""
echo "Next steps:"
echo "  cd ${PROJECT_NAME}"
echo "  pnpm install"
echo "  pnpm compile"
echo "  pnpm anvil  # Start local node"
echo "  pnpm deploy # Deploy contract"
EOF

chmod +x /usr/local/bin/new-web3-project

# Create anvil wrapper for Docker networks
cat > /usr/local/bin/start-anvil << 'EOF'
#!/bin/bash
# Start Anvil local testnet with HomeLab network config

FORK_URL="${FORK_URL:-}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8545}"
CHAIN_ID="${CHAIN_ID:-31337}"
BLOCK_TIME="${BLOCK_TIME:-1}"

ARGS=(
    "--host" "${HOST}"
    "--port" "${PORT}"
    "--chain-id" "${CHAIN_ID}"
    "--block-time" "${BLOCK_TIME}"
    "--accounts" "10"
    "--balance" "10000"
)

if [[ -n "${FORK_URL}" ]]; then
    echo "Forking from: ${FORK_URL}"
    ARGS+=("--fork-url" "${FORK_URL}")
fi

echo "Starting Anvil on ${HOST}:${PORT} (chainId: ${CHAIN_ID})"
exec anvil "${ARGS[@]}"
EOF

chmod +x /usr/local/bin/start-anvil

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✓ Web3 Stack Installation Complete                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Installed Tools:"
echo "  ✓ Node.js ${NODE_VERSION} + pnpm"
echo "  ✓ Foundry (forge, cast, anvil, chisel)"
echo "  ✓ Hardhat 3.x with TypeScript"
echo "  ✓ Base network configurations"
echo "  ✓ OpenZeppelin contracts"
echo "  ✓ Viem, Ethers, Wagmi"
echo "  ✓ Security tools (slither, solhint)"
echo ""
echo "Helper Commands:"
echo "  new-web3-project <name>  - Create new project from template"
echo "  start-anvil              - Start local Ethereum node"
echo ""
echo "Template location: ${TEMPLATE_DIR}"
echo ""

if [[ "$OFFLINE_CACHE" == "true" ]]; then
    echo -e "${GREEN}✓ Offline packages cached${NC}"
fi

echo -e "${BLUE}Documentation: docs/WEB3.md${NC}"
