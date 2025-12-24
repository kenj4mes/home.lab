# ==============================================================================
# 🔒 Vault Policy - Admin
# ==============================================================================
# Full administrative access to Vault
#
# Apply: vault policy write admin /vault/policies/admin.hcl
# ==============================================================================

# Full access to all secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage mounts
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Database secrets engine
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# PKI secrets engine
path "pki/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Transit encryption
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# System health
path "sys/health" {
  capabilities = ["read"]
}

# Seal status
path "sys/seal-status" {
  capabilities = ["read"]
}

# Audit logs
path "sys/audit*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
