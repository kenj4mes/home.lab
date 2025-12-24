# ==============================================================================
# 🔒 Vault Policy - HomeLab Applications
# ==============================================================================
# Grants read access to homelab secrets
#
# Apply: vault policy write homelab-apps /vault/policies/homelab-apps.hcl
# ==============================================================================

# Read secrets from the homelab path
path "secret/data/homelab/*" {
  capabilities = ["read", "list"]
}

# Read database credentials
path "database/creds/homelab-*" {
  capabilities = ["read"]
}

# Read PKI certificates
path "pki/issue/homelab" {
  capabilities = ["create", "update"]
}

# Renew tokens
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Lookup self
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
