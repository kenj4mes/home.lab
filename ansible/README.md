# ==============================================================================
# 🤖 HomeLab Ansible Automation
# ==============================================================================

# Ansible Automation

This directory contains Ansible playbooks and roles for automated server
provisioning and configuration management.

## 📁 Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.example.yml    # Example inventory (copy to inventory.yml)
├── playbooks/
│   └── site.yml            # Master playbook
└── roles/
    ├── common/             # Base system configuration
    ├── docker/             # Docker CE installation
    └── kubernetes/
        ├── common/         # K8s prerequisites
        ├── control-plane/  # K8s master setup
        └── worker/         # K8s worker setup
```

## 🚀 Quick Start

### 1. Install Ansible

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible

# RHEL/Fedora
sudo dnf install -y ansible-core

# pip (any OS)
pip install ansible-core ansible-lint
```

### 2. Configure Inventory

```bash
cd ansible
cp inventory.example.yml inventory.yml
# Edit inventory.yml with your hosts
```

### 3. Test Connection

```bash
ansible all -i inventory.yml -m ping
```

### 4. Run Playbooks

```bash
# Full deployment
ansible-playbook -i inventory.yml playbooks/site.yml

# Dry run (check mode)
ansible-playbook -i inventory.yml playbooks/site.yml --check --diff

# Specific tags
ansible-playbook -i inventory.yml playbooks/site.yml --tags docker

# Specific hosts
ansible-playbook -i inventory.yml playbooks/site.yml --limit docker_hosts
```

## 📋 Available Tags

| Tag | Description |
|-----|-------------|
| `common` | Base system configuration |
| `docker` | Docker installation |
| `kubernetes` | Full K8s cluster |
| `k8s-control` | K8s control plane only |
| `k8s-workers` | K8s workers only |
| `dns` | Pi-hole DNS servers |
| `storage` | Storage servers |
| `proxmox` | Proxmox hypervisors |
| `security` | Security hardening |
| `firewall` | Firewall configuration |

## 🔧 Customization

### Variables

Edit role defaults in `roles/<role>/defaults/main.yml` or override in inventory:

```yaml
all:
  vars:
    homelab_timezone: "America/New_York"
    docker_version: "24.0"
    k8s_version: "1.29.0"
```

### Adding New Roles

```bash
ansible-galaxy init roles/my_new_role
```

## 📚 Requirements

- Ansible Core 2.14+
- Python 3.9+
- SSH access to target hosts
- Sudo privileges on targets

### Required Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

Create `requirements.yml`:

```yaml
collections:
  - name: ansible.posix
  - name: community.general
  - name: community.docker
  - name: kubernetes.core
```

## 🔐 Secrets Management

For sensitive data, use Ansible Vault:

```bash
# Create encrypted file
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Run playbook with vault
ansible-playbook -i inventory.yml playbooks/site.yml --ask-vault-pass
```
