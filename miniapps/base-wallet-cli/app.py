"""
HomeLab Base Wallet CLI - REST API for Wallet Operations

Endpoints:
    GET  /health               - Health check
    GET  /wallet/new           - Generate new wallet (mnemonic + address + private key)
    GET  /wallet/balance/<addr> - Get balance for address
    POST /wallet/send          - Send transaction (requires PRIVATE_KEY env var)
    GET  /block/<number>       - Get block info (use 'latest' for latest block)
    GET  /chain                - Get chain info (chainId, blockNumber, gasPrice)

Environment Variables:
    RPC_URL      - Base node RPC URL (default: http://base-node:8545)
    CHAIN_ID     - Chain ID (default: 8453 for Base Mainnet)
    PRIVATE_KEY  - Private key for signing transactions (optional)
"""

import os
import json
from flask import Flask, request, jsonify
from eth_account import Account
from web3 import Web3
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Configuration
RPC_URL = os.getenv('RPC_URL', 'http://base-node:8545')
CHAIN_ID = int(os.getenv('CHAIN_ID', '8453'))
PRIVATE_KEY = os.getenv('PRIVATE_KEY', '')

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(RPC_URL))


# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

def get_web3():
    """Get Web3 instance, reconnect if needed."""
    global w3
    if not w3.is_connected():
        w3 = Web3(Web3.HTTPProvider(RPC_URL))
    return w3


def format_balance(wei_balance):
    """Convert wei to ether and format."""
    return float(Web3.from_wei(wei_balance, 'ether'))


# ==============================================================================
# API ENDPOINTS
# ==============================================================================

@app.route('/health')
def health():
    """Health check endpoint."""
    try:
        web3 = get_web3()
        connected = web3.is_connected()
        block = web3.eth.block_number if connected else None
        return jsonify({
            'status': 'healthy' if connected else 'degraded',
            'rpc_connected': connected,
            'rpc_url': RPC_URL,
            'chain_id': CHAIN_ID,
            'latest_block': block
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500


@app.route('/wallet/new')
def new_wallet():
    """Generate a new wallet with mnemonic."""
    try:
        # Enable mnemonic features
        Account.enable_unaudited_hdwallet_features()
        
        # Generate new account with mnemonic
        account, mnemonic = Account.create_with_mnemonic()
        
        return jsonify({
            'address': account.address,
            'private_key': account.key.hex(),
            'mnemonic': mnemonic,
            'warning': 'Store these credentials securely! Never share your private key or mnemonic.'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/wallet/balance/<address>')
def get_balance(address):
    """Get balance for an address."""
    try:
        # Validate address
        if not Web3.is_address(address):
            return jsonify({'error': 'Invalid address format'}), 400
        
        checksum_address = Web3.to_checksum_address(address)
        
        web3 = get_web3()
        balance_wei = web3.eth.get_balance(checksum_address)
        
        return jsonify({
            'address': checksum_address,
            'balance_wei': str(balance_wei),
            'balance_eth': format_balance(balance_wei),
            'chain_id': CHAIN_ID
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/wallet/send', methods=['POST'])
def send_transaction():
    """Send a transaction (requires PRIVATE_KEY env var)."""
    try:
        if not PRIVATE_KEY:
            return jsonify({
                'error': 'PRIVATE_KEY environment variable not set',
                'hint': 'Set PRIVATE_KEY in docker-compose or use Docker secrets'
            }), 400
        
        data = request.json
        if not data:
            return jsonify({'error': 'JSON body required'}), 400
        
        to_address = data.get('to')
        value_eth = data.get('value', 0)
        data_hex = data.get('data', '0x')
        
        if not to_address:
            return jsonify({'error': 'Missing "to" address'}), 400
        
        if not Web3.is_address(to_address):
            return jsonify({'error': 'Invalid "to" address'}), 400
        
        web3 = get_web3()
        account = Account.from_key(PRIVATE_KEY)
        
        # Build transaction
        nonce = web3.eth.get_transaction_count(account.address)
        gas_price = web3.eth.gas_price
        
        tx = {
            'nonce': nonce,
            'to': Web3.to_checksum_address(to_address),
            'value': Web3.to_wei(float(value_eth), 'ether'),
            'gas': 21000,  # Standard transfer gas
            'gasPrice': gas_price,
            'chainId': CHAIN_ID,
            'data': data_hex
        }
        
        # Estimate gas if data is present
        if data_hex and data_hex != '0x':
            tx['gas'] = web3.eth.estimate_gas(tx)
        
        # Sign and send
        signed = account.sign_transaction(tx)
        tx_hash = web3.eth.send_raw_transaction(signed.rawTransaction)
        
        return jsonify({
            'tx_hash': tx_hash.hex(),
            'from': account.address,
            'to': to_address,
            'value_eth': value_eth,
            'gas_price_gwei': Web3.from_wei(gas_price, 'gwei'),
            'status': 'pending'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/block/<block_id>')
def get_block(block_id):
    """Get block information."""
    try:
        web3 = get_web3()
        
        if block_id == 'latest':
            block = web3.eth.get_block('latest')
        else:
            block = web3.eth.get_block(int(block_id))
        
        return jsonify({
            'number': block.number,
            'hash': block.hash.hex(),
            'parent_hash': block.parentHash.hex(),
            'timestamp': block.timestamp,
            'gas_used': block.gasUsed,
            'gas_limit': block.gasLimit,
            'transaction_count': len(block.transactions),
            'miner': block.miner if hasattr(block, 'miner') else None
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/chain')
def get_chain_info():
    """Get chain information."""
    try:
        web3 = get_web3()
        
        return jsonify({
            'chain_id': web3.eth.chain_id,
            'block_number': web3.eth.block_number,
            'gas_price_gwei': float(Web3.from_wei(web3.eth.gas_price, 'gwei')),
            'connected': web3.is_connected(),
            'rpc_url': RPC_URL
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/tx/<tx_hash>')
def get_transaction(tx_hash):
    """Get transaction details."""
    try:
        web3 = get_web3()
        
        tx = web3.eth.get_transaction(tx_hash)
        receipt = web3.eth.get_transaction_receipt(tx_hash)
        
        return jsonify({
            'hash': tx.hash.hex(),
            'from': tx['from'],
            'to': tx.to,
            'value_eth': format_balance(tx.value),
            'gas': tx.gas,
            'gas_price_gwei': float(Web3.from_wei(tx.gasPrice, 'gwei')),
            'nonce': tx.nonce,
            'block_number': tx.blockNumber,
            'status': 'success' if receipt.status == 1 else 'failed',
            'gas_used': receipt.gasUsed
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# MAIN
# ==============================================================================

if __name__ == '__main__':
    print(f"""
╔══════════════════════════════════════════════════════════════════════════════╗
║                     🔗 Base Wallet CLI API                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  RPC URL:    {RPC_URL:<55} ║
║  Chain ID:   {CHAIN_ID:<55} ║
║  Private Key: {'SET' if PRIVATE_KEY else 'NOT SET':<54} ║
╚══════════════════════════════════════════════════════════════════════════════╝

Endpoints:
  GET  /health               - Health check
  GET  /wallet/new           - Generate new wallet
  GET  /wallet/balance/<addr> - Get balance
  POST /wallet/send          - Send transaction
  GET  /block/<number>       - Get block info
  GET  /chain                - Get chain info
  GET  /tx/<hash>            - Get transaction details
""")
    app.run(host='0.0.0.0', port=5000, debug=False)
