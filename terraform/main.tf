# ==============================================================================
# 🏗️ HomeLab Infrastructure as Code - Proxmox Provisioning
# ==============================================================================
# Provider: Telmate/proxmox
# Resources: VM, ZFS Datasets, Cloud-Init
# ==============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# ==============================================================================
# 🖥️ CORE DOCKER HOST VM
# ==============================================================================

resource "proxmox_vm_qemu" "docker_host" {
  name        = "homelab-docker"
  target_node = var.proxmox_node
  vmid        = var.vm_id
  desc        = "HomeLab Core Docker Host (Provisioned via Terraform)"
  
  # Cloud-Init Template
  clone = var.debian_template_name
  
  # Hardware Specs
  cores   = 4
  sockets = 1
  cpu     = "host"
  memory  = 8192
  
  # Network
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Storage
  disk {
    size    = "100G"
    type    = "virtio"
    storage = "FlashBang"      # Config/Local Pool
    iothread = 1
  }
  
  # Additional Mount (Bulk Media)
  # In Proxmox, we often pass through the disk or mount via 9p/NFS
  # This section assumes a secondary virtual disk on the HDD pool
  disk {
    size    = var.media_disk_size
    type    = "virtio"
    storage = "Tumadre"        # Media Pool
  }

  # Cloud-Init Config
  os_type    = "cloud-init"
  ipconfig0  = "ip=${var.vm_ip}/24,gw=${var.vm_gateway}"
  sshkeys    = var.ssh_public_key
  
  # Lifecycle (Ignore changes to network which Proxmox might update)
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ==============================================================================
# 💾 ZFS DATASETS (Optional - Managed via shell usually, but defined here)
# ==============================================================================
# Note: The telmate provider has limited ZFS dataset support natively.
# Usually done via 'proxmox_storage_iso' or manual 'remote-exec'.
