# ==============================================================================
# 🔧 HomeLab Terraform Variables
# ==============================================================================

variable "proxmox_api_url" {
  description = "The URL for the Proxmox API (e.g. https://192.168.1.10:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "The token ID for the Proxmox API"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The token secret for the Proxmox API"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The target Proxmox node name"
  type        = string
  default     = "pve"
}

variable "vm_id" {
  description = "The ID of the VM to create"
  type        = number
  default     = 100
}

variable "debian_template_name" {
  description = "The name of the Debian cloud-init template"
  type        = string
  default     = "debian-12-cloudinit"
}

variable "vm_ip" {
  description = "The static IP for the VM"
  type        = string
}

variable "vm_gateway" {
  description = "The gateway for the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key to inject"
  type        = string
}

variable "media_disk_size" {
  description = "Size of the media disk (e.g. 2T)"
  type        = string
  default     = "500G"
}
