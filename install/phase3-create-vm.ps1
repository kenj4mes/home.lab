<#
.SYNOPSIS
    Phase 3: Create Debian 12 VM on Proxmox
.DESCRIPTION
    Creates a Debian 12 VM with optimal settings for Docker workloads
.PARAMETER ProxmoxIP
    IP address of the Proxmox host
.PARAMETER VMID
    VM ID to use (default: 100)
.PARAMETER VMName
    Name for the VM (default: docker-host)
.PARAMETER Cores
    Number of CPU cores (default: 4)
.PARAMETER Memory
    RAM in MB (default: 8192)
.PARAMETER DiskSize
    Disk size in GB (default: 100)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProxmoxIP,
    [string]$Username = "root",
    [int]$VMID = 100,
    [string]$VMName = "docker-host",
    [int]$Cores = 4,
    [int]$Memory = 8192,
    [int]$DiskSize = 100
)

$ErrorActionPreference = "Stop"

Write-Host @"

+==============================================================================+
|                     Phase 3: Create Debian VM                                 |
+==============================================================================+

"@ -ForegroundColor Blue

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Proxmox:  $ProxmoxIP"
Write-Host "  VM ID:    $VMID"
Write-Host "  Name:     $VMName"
Write-Host "  Cores:    $Cores"
Write-Host "  Memory:   $Memory MB"
Write-Host "  Disk:     $DiskSize GB"
Write-Host ""

# ==============================================================================
# Create VM Creation Script
# ==============================================================================

$vmScript = @"
#!/bin/bash
set -e

VMID=$VMID
VMNAME="$VMName"
CORES=$Cores
MEMORY=$Memory
DISK_SIZE=$DiskSize

echo "Creating Debian 12 VM..."

# Download Debian cloud image if not present
DEBIAN_IMG="/var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"
if [[ ! -f "\$DEBIAN_IMG" ]]; then
    echo "Downloading Debian 12 cloud image..."
    wget -q --show-progress -O "\$DEBIAN_IMG" \
        "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
fi

# Determine storage
if pvesm status | grep -q "fast-pool"; then
    STORAGE="fast-pool"
elif pvesm status | grep -q "local-zfs"; then
    STORAGE="local-zfs"
else
    STORAGE="local"
fi
echo "Using storage: \$STORAGE"

# Check if VM exists
if qm status \$VMID &>/dev/null; then
    echo "VM \$VMID already exists!"
    read -p "Delete and recreate? (y/N): " confirm
    if [[ "\$confirm" =~ ^[Yy]$ ]]; then
        qm stop \$VMID 2>/dev/null || true
        qm destroy \$VMID
    else
        exit 0
    fi
fi

# Create VM
qm create \$VMID \
    --name "\$VMNAME" \
    --memory \$MEMORY \
    --cores \$CORES \
    --cpu host \
    --net0 virtio,bridge=vmbr0 \
    --scsihw virtio-scsi-pci \
    --ostype l26 \
    --agent 1

# Import disk
echo "Importing disk image..."
qm importdisk \$VMID "\$DEBIAN_IMG" \$STORAGE

# Configure disk
qm set \$VMID --scsi0 \$STORAGE:vm-\$VMID-disk-0,ssd=1
qm resize \$VMID scsi0 \${DISK_SIZE}G

# Add cloud-init drive
qm set \$VMID --ide2 \$STORAGE:cloudinit

# Configure boot
qm set \$VMID --boot order=scsi0

# Cloud-init settings
qm set \$VMID \
    --ciuser homelab \
    --cipassword homelab \
    --ipconfig0 ip=dhcp \
    --sshkeys ~/.ssh/authorized_keys 2>/dev/null

# Enable serial console
qm set \$VMID --serial0 socket --vga serial0

# Start VM
echo "Starting VM..."
qm start \$VMID

echo ""
echo "[OK] VM created and started"
echo ""
echo "Waiting for VM to get IP address..."

# Wait for IP
for i in {1..60}; do
    IP=\$(qm agent \$VMID network-get-interfaces 2>/dev/null | grep -oP '"ip-address"\s*:\s*"\K192\.168\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n "\$IP" ]]; then
        echo "VM IP: \$IP"
        echo "\$IP" > /tmp/vm_ip
        break
    fi
    sleep 2
done

if [[ -z "\$IP" ]]; then
    echo "Could not detect VM IP. Check Proxmox console."
    echo "Default credentials: homelab / homelab"
fi
"@

# ==============================================================================
# Execute on Proxmox
# ==============================================================================

Write-Host "Creating VM on Proxmox..." -ForegroundColor Cyan

# Copy script to Proxmox
$vmScript | ssh "${Username}@${ProxmoxIP}" "cat > /root/homelab-setup/create-vm.sh && chmod +x /root/homelab-setup/create-vm.sh"

# Execute
ssh "${Username}@${ProxmoxIP}" "/root/homelab-setup/create-vm.sh"

# Get VM IP
Write-Host ""
Write-Host "Retrieving VM IP address..." -ForegroundColor Cyan
$VMIP = ssh "${Username}@${ProxmoxIP}" "cat /tmp/vm_ip 2>/dev/null || echo ''"

if ($VMIP) {
    Write-Host "[OK] VM IP: $VMIP" -ForegroundColor Green
    
    # Return IP for orchestrator
    return @{
        VMIP = $VMIP.Trim()
        VMID = $VMID
    }
} else {
    Write-Host "Could not auto-detect VM IP." -ForegroundColor Yellow
    Write-Host "Check Proxmox console or DHCP leases." -ForegroundColor Yellow
    Write-Host "Default credentials: homelab / homelab" -ForegroundColor Cyan
}
