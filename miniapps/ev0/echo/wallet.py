"""
Digital Body - Sovereign Agent Wallet
Coinbase AgentKit Integration for Base

The agent's financial identity and capabilities:
- MPC wallet (no private key exposure)
- USDC payments
- Token deployment
- Basename identity
"""

import json
import os
from typing import Any, Optional

import structlog

logger = structlog.get_logger(__name__)

# Contract addresses on Base Mainnet
USDC_BASE = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
WETH_BASE = "0x4200000000000000000000000000000000000006"


class DigitalBody:
    """
    Digital Body - The Agent's Wallet
    
    Uses Coinbase AgentKit for secure MPC wallet operations.
    No private keys are ever exposed - all signing happens in
    Coinbase's secure infrastructure.
    
    Capabilities:
    - Send/receive USDC and ETH
    - Deploy ERC-20 tokens
    - Register Basename identity
    - Check balances
    - Sign messages
    
    Example:
        >>> body = DigitalBody(
        ...     cdp_api_key_name="...",
        ...     cdp_api_key_private_key="...",
        ... )
        >>> await body.initialize()
        >>> balance = await body.get_usdc_balance()
        >>> await body.send_usdc("0x...", 10.0)
    """
    
    def __init__(
        self,
        cdp_api_key_name: Optional[str] = None,
        cdp_api_key_private_key: Optional[str] = None,
        network_id: str = "base-mainnet",
        wallet_file: str = "wallet_data.json",
    ):
        """
        Initialize Digital Body.
        
        Args:
            cdp_api_key_name: CDP API key name
            cdp_api_key_private_key: CDP API private key
            network_id: Network to operate on
            wallet_file: Path to persist wallet data
        """
        self.cdp_api_key_name = cdp_api_key_name or os.getenv("CDP_API_KEY_NAME")
        self.cdp_api_key_private_key = cdp_api_key_private_key or os.getenv("CDP_API_KEY_PRIVATE_KEY")
        self.network_id = network_id
        self.wallet_file = wallet_file
        
        self._wallet = None
        self._agentkit = None
        self.address: Optional[str] = None
        self.basename: Optional[str] = None
        
    async def initialize(self) -> None:
        """
        Initialize the wallet via AgentKit.
        
        Either loads existing wallet from file or creates new one.
        """
        try:
            from cdp_agentkit_core.actions import CdpAction
            from cdp import Cdp, Wallet
            
            # Configure CDP SDK
            Cdp.configure(
                api_key_name=self.cdp_api_key_name,
                api_key_private_key=self.cdp_api_key_private_key,
            )
            
            # Load or create wallet
            if os.path.exists(self.wallet_file):
                self._wallet = await self._load_wallet()
                logger.info("wallet.loaded", address=self.address)
            else:
                self._wallet = await self._create_wallet()
                logger.info("wallet.created", address=self.address)
            
            self.address = self._wallet.default_address.address_id
            
        except ImportError:
            logger.warning("wallet.agentkit_not_installed",
                         note="Install cdp-agentkit-core for wallet features")
        except Exception as e:
            logger.error("wallet.init_failed", error=str(e))
            raise
    
    async def _create_wallet(self):
        """Create new MPC wallet"""
        from cdp import Wallet
        
        wallet = Wallet.create(network_id=self.network_id)
        
        # Persist wallet data
        wallet_data = wallet.export_data()
        with open(self.wallet_file, "w") as f:
            json.dump(wallet_data.to_dict(), f)
        
        return wallet
    
    async def _load_wallet(self):
        """Load existing wallet from file"""
        from cdp import Wallet, WalletData
        
        with open(self.wallet_file, "r") as f:
            data = json.load(f)
        
        wallet_data = WalletData.from_dict(data)
        return Wallet.import_data(wallet_data)
    
    # ==========================================================================
    # BALANCE OPERATIONS
    # ==========================================================================
    
    async def get_eth_balance(self) -> float:
        """
        Get ETH balance.
        
        Returns:
            ETH balance as float
        """
        if not self._wallet:
            return 0.0
        
        try:
            balance = self._wallet.balance("eth")
            return float(balance)
        except Exception as e:
            logger.warning("wallet.balance_failed", error=str(e))
            return 0.0
    
    async def get_usdc_balance(self) -> float:
        """
        Get USDC balance.
        
        Returns:
            USDC balance as float
        """
        if not self._wallet:
            return 0.0
        
        try:
            balance = self._wallet.balance("usdc")
            return float(balance)
        except Exception as e:
            logger.warning("wallet.usdc_balance_failed", error=str(e))
            return 0.0
    
    async def get_balances(self) -> dict[str, float]:
        """
        Get all token balances.
        
        Returns:
            Dict of token symbol to balance
        """
        return {
            "eth": await self.get_eth_balance(),
            "usdc": await self.get_usdc_balance(),
        }
    
    # ==========================================================================
    # TRANSFER OPERATIONS
    # ==========================================================================
    
    async def send_eth(
        self,
        to: str,
        amount: float,
    ) -> dict[str, Any]:
        """
        Send ETH to an address.
        
        Args:
            to: Recipient address
            amount: Amount in ETH
            
        Returns:
            Transaction result
        """
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            transfer = self._wallet.transfer(
                amount=amount,
                asset_id="eth",
                destination=to,
            )
            
            # Wait for confirmation
            transfer.wait()
            
            logger.info("wallet.eth_sent",
                       to=to,
                       amount=amount,
                       tx_hash=transfer.transaction_hash)
            
            return {
                "status": "success",
                "tx_hash": transfer.transaction_hash,
                "amount": amount,
                "to": to,
            }
            
        except Exception as e:
            logger.error("wallet.send_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def send_usdc(
        self,
        to: str,
        amount: float,
    ) -> dict[str, Any]:
        """
        Send USDC to an address.
        
        Args:
            to: Recipient address
            amount: Amount in USDC
            
        Returns:
            Transaction result
        """
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            transfer = self._wallet.transfer(
                amount=amount,
                asset_id="usdc",
                destination=to,
            )
            
            transfer.wait()
            
            logger.info("wallet.usdc_sent",
                       to=to,
                       amount=amount,
                       tx_hash=transfer.transaction_hash)
            
            return {
                "status": "success",
                "tx_hash": transfer.transaction_hash,
                "amount": amount,
                "to": to,
            }
            
        except Exception as e:
            logger.error("wallet.send_usdc_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # TOKEN DEPLOYMENT
    # ==========================================================================
    
    async def deploy_token(
        self,
        name: str,
        symbol: str,
        total_supply: int,
    ) -> dict[str, Any]:
        """
        Deploy a new ERC-20 token.
        
        Args:
            name: Token name
            symbol: Token symbol
            total_supply: Initial supply (in whole tokens)
            
        Returns:
            Deployment result with contract address
        """
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            contract = self._wallet.deploy_token(
                name=name,
                symbol=symbol,
                total_supply=total_supply,
            )
            
            contract.wait()
            
            logger.info("wallet.token_deployed",
                       name=name,
                       symbol=symbol,
                       address=contract.contract_address)
            
            return {
                "status": "success",
                "contract_address": contract.contract_address,
                "name": name,
                "symbol": symbol,
                "total_supply": total_supply,
            }
            
        except Exception as e:
            logger.error("wallet.deploy_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # BASENAME (IDENTITY)
    # ==========================================================================
    
    async def register_basename(self, name: str) -> dict[str, Any]:
        """
        Register a Basename for the agent.
        
        Basenames are ENS-compatible names on Base (e.g., myagent.base.eth)
        
        Args:
            name: Desired basename (without .base.eth)
            
        Returns:
            Registration result
        """
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            # Use AgentKit's basename action
            from cdp_agentkit_core.actions.basename import register_basename
            
            result = register_basename(
                wallet=self._wallet,
                basename=name,
            )
            
            self.basename = f"{name}.base.eth"
            
            logger.info("wallet.basename_registered", basename=self.basename)
            
            return {
                "status": "success",
                "basename": self.basename,
            }
            
        except Exception as e:
            logger.error("wallet.basename_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # SIGNING
    # ==========================================================================
    
    async def sign_message(self, message: str) -> dict[str, Any]:
        """
        Sign a message with the wallet.
        
        Args:
            message: Message to sign
            
        Returns:
            Signature result
        """
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            signature = self._wallet.sign_message(message)
            
            return {
                "status": "success",
                "signature": signature,
                "message": message,
                "signer": self.address,
            }
            
        except Exception as e:
            logger.error("wallet.sign_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # FAUCET (TESTNET ONLY)
    # ==========================================================================
    
    async def request_faucet(self) -> dict[str, Any]:
        """
        Request testnet funds from faucet.
        
        Only works on testnet networks.
        
        Returns:
            Faucet result
        """
        if "mainnet" in self.network_id:
            return {"status": "error", "error": "Faucet not available on mainnet"}
        
        if not self._wallet:
            return {"status": "error", "error": "Wallet not initialized"}
        
        try:
            faucet = self._wallet.faucet()
            faucet.wait()
            
            logger.info("wallet.faucet_received")
            
            return {
                "status": "success",
                "tx_hash": faucet.transaction_hash,
            }
            
        except Exception as e:
            logger.error("wallet.faucet_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get wallet status"""
        return {
            "initialized": self._wallet is not None,
            "address": self.address,
            "basename": self.basename,
            "network": self.network_id,
        }
    
    async def close(self) -> None:
        """Cleanup (save wallet state)"""
        if self._wallet:
            try:
                wallet_data = self._wallet.export_data()
                with open(self.wallet_file, "w") as f:
                    json.dump(wallet_data.to_dict(), f)
            except Exception as e:
                logger.warning("wallet.save_failed", error=str(e))
        
        logger.info("wallet.closed")
