import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

// Environment - use Docker secrets or .env
const DEPLOYER_KEY = process.env.DEPLOYER_PRIVATE_KEY || 
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Default Anvil key
const BASESCAN_KEY = process.env.BASESCAN_API_KEY || "";
const ETHERSCAN_KEY = process.env.ETHERSCAN_API_KEY || "";

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
      url: process.env.ANVIL_URL || "http://localhost:8545",
      chainId: 31337,
    },
    
    // HomeLab Base Node (Docker network)
    "homelab-base": {
      url: process.env.BASE_RPC_URL || "http://base-node:8545",
      chainId: 8453,
      accounts: [DEPLOYER_KEY],
    },
    
    // Base Mainnet (online)
    base: {
      url: process.env.BASE_MAINNET_RPC || "https://mainnet.base.org",
      chainId: 8453,
      accounts: [DEPLOYER_KEY],
    },
    
    // Base Sepolia (testnet, online)
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
