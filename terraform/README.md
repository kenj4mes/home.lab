# 🏗️ Terraform

Infrastructure as Code for Proxmox VM provisioning.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Proxmox VM resources |
| `variables.tf` | Configuration variables |

## Prerequisites

- Proxmox VE cluster
- Terraform >= 1.0
- telmate/proxmox provider

## Usage

```bash
cd terraform

# Initialize
terraform init

# Plan changes
terraform plan -var-file="my-cluster.tfvars"

# Apply
terraform apply -var-file="my-cluster.tfvars"
```

## Variables

Create a `.tfvars` file (not committed to git):

```hcl
proxmox_api_url  = "https://pve.local:8006/api2/json"
proxmox_user     = "root@pam"
proxmox_password = "your-password"
target_node      = "pve"
```

## Resources Created

- Ubuntu/Debian VMs with cloud-init
- Network configuration
- SSH key provisioning
- Docker pre-installed

See [docs/PROXMOX.md](../docs/PROXMOX.md) for detailed Proxmox setup.
