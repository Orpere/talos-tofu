#!/bin/bash

# Simple Proxmox Cloud-Init Template Creator
# Creates VM templates from Ubuntu Debian  and alpine cloud images
# Requires: Proxmox VE, qm command line tool, wget, qemu-img
# Usage: Run this script on a Proxmox VE host with sufficient permissions
# Ensure script is run as root

# Configuration
MEMORY=2048
CORES=2
STORAGE="local-lvm"
START_VM_ID=9000

# Get next available VM ID
get_next_vm_id() {
    local vm_id=$START_VM_ID
    while [[ -f "/etc/pve/qemu-server/${vm_id}.conf" ]]; do
        ((vm_id++))
    done
    echo $vm_id
}

# Distribution configurations
declare -A DISTROS=(
    [ubuntu_24.04]="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img ubuntu"
    [ubuntu_22.04]="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img ubuntu"
    [ubuntu_20.04]="https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img ubuntu"
    [debian_12]="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 debian"
    [debian_11]="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2 debian"
    [alpine_3.22]="https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/generic_alpine-3.22.0-x86_64-bios-cloudinit-r0.qcow2 alpine"
)

# Show menu and get selection
select_distro() {
    echo "Select Linux Distribution:" >&2
    echo "1) Ubuntu 24.04 LTS" >&2
    echo "2) Ubuntu 22.04 LTS" >&2
    echo "3) Ubuntu 20.04 LTS" >&2
    echo "4) Debian 12" >&2
    echo "5) Debian 11" >&2
    echo "6) Alpine 3.22" >&2
    echo "7) Clean all templates and images" >&2
    read -p "Choice (1-7): " choice >&2
    
    case $choice in
        1) echo "ubuntu_24.04" ;;
        2) echo "ubuntu_22.04" ;;
        3) echo "ubuntu_20.04" ;;
        4) echo "debian_12" ;;
        5) echo "debian_11" ;;
        6) echo "alpine_3.22" ;;
        7) echo "cleanup" ;;
        *) echo "Invalid choice" >&2; exit 1 ;;
    esac
}

# Clean all templates and images
cleanup_templates() {
    echo "Cleaning all templates and images..."
    echo "WARNING: This will remove ALL VM templates starting from ID $START_VM_ID and their storage!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
    
    # Find and remove all templates
    local removed_count=0
    for conf_file in /etc/pve/qemu-server/*.conf; do
        [[ -f "$conf_file" ]] || continue
        local vm_id
        vm_id=$(basename "$conf_file" .conf)
        
        # Only process VMs with ID >= START_VM_ID
        if [[ $vm_id =~ ^[0-9]+$ ]] && [[ $vm_id -ge $START_VM_ID ]]; then
            # Check if it's a template
            if grep -q "template: 1" "$conf_file" 2>/dev/null; then
                echo "Removing template VM $vm_id..."
                qm destroy "$vm_id" 2>/dev/null || true
                ((removed_count++))
            fi
        fi
    done
    
    # Clean up cloud images in ISO storage
    echo "Cleaning cloud images..."
    cd /var/lib/vz/template/iso/ 2>/dev/null || true
    for image in ubuntu-*-cloudimg.img debian-*-cloudimg.img alpine-*-cloudimg.img; do
        if [[ -f "$image" ]]; then
            echo "Removing image: $image"
            rm -f "$image"
        fi
    done
    
    echo "Cleanup completed! Removed $removed_count templates and associated images."
    exit 0
}

# Download and setup image
download_image() {
    echo "Downloading $DISTRO_NAME $VERSION cloud image..."
    cd /var/lib/vz/template/iso/ || exit 1
    
    # Clean up existing files
    rm -f "$IMAGE_FILE" "$(basename "$DOWNLOAD_URL")"
    
    # Download and rename
    wget -q --show-progress "$DOWNLOAD_URL" -O "$IMAGE_FILE"
    
    # Verify image
    if ! qemu-img info "$IMAGE_FILE" >/dev/null 2>&1; then
        echo "Error: Invalid image file" >&2
        exit 1
    fi
    echo "Image ready: $IMAGE_FILE"
}

# Create VM
create_vm() {
    echo "Creating VM $VM_ID..."
    
    # Remove existing VM if it exists
    qm destroy "$VM_ID" 2>/dev/null || true
    
    # Create new VM
    qm create "$VM_ID" \
        --name "$VM_NAME" \
        --memory "$MEMORY" \
        --cores "$CORES" \
        --net0 virtio,bridge=vmbr0 \
        --scsihw virtio-scsi-pci \
        --ostype l26 \
        --agent enabled=1
    
    # Import and attach disk
    qm importdisk "$VM_ID" "$IMAGE_FILE" "$STORAGE" >/dev/null
    qm set "$VM_ID" \
        --scsi0 "$STORAGE":vm-"$VM_ID"-disk-0 \
        --boot c \
        --bootdisk scsi0 \
        --ide2 "$STORAGE":cloudinit \
        --serial0 socket \
        --vga serial0 \
        --ciuser "$USERNAME"
    
    # Setup SSH keys if available
    if ls ~/.ssh/*.pub >/dev/null 2>&1; then
        echo "Adding SSH keys..."
        SSH_KEY_FILE="/tmp/ssh_keys_$$"
        cat ~/.ssh/*.pub > "$SSH_KEY_FILE" 2>/dev/null
        qm set "$VM_ID" --sshkeys "$SSH_KEY_FILE"
        rm -f "$SSH_KEY_FILE"
    fi
    
    # Convert to template
    qm template "$VM_ID"
    echo "Template $VM_NAME created successfully!"
}

# Main execution
main() {
    echo "Proxmox Cloud-Init Template Creator"
    echo "==================================="
    
    # Get selection
    DISTRO=$(select_distro)
    
    # Handle cleanup option
    if [[ "$DISTRO" == "cleanup" ]]; then
        cleanup_templates
        return
    fi
    
    # Setup for template creation
    VM_ID=$(get_next_vm_id)
    
    # Parse distribution configuration
    IFS=' ' read -r DOWNLOAD_URL USERNAME <<< "${DISTROS[$DISTRO]}"
    DISTRO_NAME=$(echo "$DISTRO" | cut -d'_' -f1)
    VERSION=$(echo "$DISTRO" | cut -d'_' -f2)
    VM_NAME="${DISTRO_NAME}-${VERSION}-template"
    IMAGE_FILE="${DISTRO_NAME}-${VERSION}-cloudimg.img"
    
    echo "Creating: $VM_NAME (ID: $VM_ID)"
    echo ""
    
    download_image
    create_vm
    
    echo ""
    echo "Template ready! To use:"
    echo "  qm clone $VM_ID <new-vm-id> --name <vm-name>"
    echo "  qm resize <new-vm-id> scsi0 +10G"
    echo "  qm start <new-vm-id>"
}

# Run main function
main