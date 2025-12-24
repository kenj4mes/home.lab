# ==============================================================================
# 🔒 Vault Agent Configuration
# ==============================================================================
# Auto-authentication and secret caching for applications
#
# Location: ${CONFIG_PATH}/vault/agent.hcl
# ==============================================================================

# Connection to Vault server
vault {
  address = "http://vault:8200"
  retry {
    num_retries = 5
  }
}

# Auto-auth with AppRole (configure in Vault first)
auto_auth {
  method "approle" {
    config = {
      role_id_file_path   = "/vault/config/role_id"
      secret_id_file_path = "/vault/config/secret_id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault-agent/token"
      mode = 0644
    }
  }
}

# Cache secrets in memory
cache {
  use_auto_auth_token = true
}

# Optional: Listen for proxied requests
listener "tcp" {
  address     = "127.0.0.1:8100"
  tls_disable = true
}

# Template for rendering secrets to files
template {
  source      = "/vault/templates/db-creds.ctmpl"
  destination = "/tmp/vault-agent/db-creds.json"
  perms       = 0600
  
  # Re-render on secret rotation
  command     = "echo 'Secrets updated at $(date)'"
}

# Template for API keys
template {
  source      = "/vault/templates/api-keys.ctmpl"
  destination = "/tmp/vault-agent/api-keys.env"
  perms       = 0600
}
