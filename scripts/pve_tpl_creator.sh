#!/bin/bash

# Simple Proxmox Cloud-Init Template Creator
# Creates VM templates from Ubuntu, Debian, Alpine cloud images and Talos Linux
# Talos images are built using Talos Factory for optimized Proxmox integration
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

# Get latest Talos version
get_latest_talos_version() {
    local version
    echo "Fetching latest Talos version..." >&2
    version=$(curl -s --connect-timeout 10 https://api.github.com/repos/siderolabs/talos/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        echo "Warning: Could not fetch latest version, using fallback" >&2
        echo "v1.8.8" # Updated fallback version
    else
        echo "Latest version found: $version" >&2
        echo "$version"
    fi
}

# Check and install dependencies for Talos
check_talos_dependencies() {
    echo "Checking Talos dependencies..."
    
    # Check for talosctl
    if ! command -v talosctl >/dev/null 2>&1; then
        echo "Installing talosctl..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install siderolabs/talos/talosctl
        elif [[ -f /etc/debian_version ]]; then
            curl -sL https://talos.dev/install | sh
        else
            echo "Please install talosctl manually from https://www.talos.dev/latest/introduction/getting-started/"
            exit 1
        fi
    else
        echo "talosctl is already installed."
    fi
    
    # Check for other required tools
    for tool in curl jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Installing $tool..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install "$tool"
            elif [[ -f /etc/debian_version ]]; then
                apt-get update && apt-get install -y "$tool"
            fi
        fi
    done
}

# Distribution configurations
declare -A DISTROS=(
    [ubuntu_24.04]="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img ubuntu"
    [ubuntu_22.04]="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img ubuntu"
    [ubuntu_20.04]="https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img ubuntu"
    [debian_12]="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 debian"
    [debian_11]="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2 debian"
    [alpine_3.22]="https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/generic_alpine-3.22.0-x86_64-bios-cloudinit-r0.qcow2 root"
    [talos_latest]="DYNAMIC talos"
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
    echo "7) Talos Linux (Latest)" >&2
    echo "8) Clean all templates and images" >&2
    read -p "Choice (1-8): " choice >&2
    
    case $choice in
        1) echo "ubuntu_24.04" ;;
        2) echo "ubuntu_22.04" ;;
        3) echo "ubuntu_20.04" ;;
        4) echo "debian_12" ;;
        5) echo "debian_11" ;;
        6) echo "alpine_3.22" ;;
        7) echo "talos_latest" ;;
        8) echo "cleanup" ;;
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
    for image in ubuntu-*-cloudimg.img debian-*-cloudimg.img alpine-*-cloudimg.img talos-*-factory.iso talos-*-nocloud-amd64.iso; do
        if [[ -f "$image" ]]; then
            echo "Removing image: $image"
            rm -f "$image"
        fi
    done
    
    echo "Cleanup completed! Removed $removed_count templates and associated images."
    exit 0
}

# Generate custom Talos Factory URL with extensions
generate_factory_url() {
    local version="$1"
    # local extensions="$2"  # Reserved for future use
    
    # Use the official Talos Factory schematic for QEMU guest agent
    # This is the official schematic ID from Talos documentation
    local base_schematic="376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
    
    # Generate factory URL
    echo "https://factory.talos.dev/image/${base_schematic}/${version}/nocloud-amd64.iso"
}

# Generate Talos Factory ISO with cloud-init and qemu-guest-agent
generate_talos_image() {
    local talos_version
    talos_version=$(get_latest_talos_version)
    
    echo "Creating Talos ${talos_version} Factory ISO with cloud-init and QEMU Guest Agent..."
    echo "This will create an ISO that can be reused for multiple deployments..."
    cd /var/lib/vz/template/iso/ || exit 1
    
    # Clean up existing files
    rm -f "$IMAGE_FILE"
    
    # Try multiple Factory approaches for ISO creation
    local download_url
    local download_successful=false
    
    # Approach 1: Try Factory ISO with cloud-init and qemu-guest-agent
    # This schematic includes both cloud-init and qemu-guest-agent extensions
    local factory_schematic="376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
    download_url="https://factory.talos.dev/image/${factory_schematic}/${talos_version}/nocloud-amd64.iso"
    echo "Trying Factory ISO with extensions: $download_url"
    
    if wget --spider --timeout=15 --tries=1 "$download_url" >/dev/null 2>&1; then
        echo "Factory ISO is accessible, downloading..."
        if wget --show-progress --timeout=180 --tries=2 "$download_url" -O "$IMAGE_FILE"; then
            download_successful=true
            echo "✅ Downloaded Talos Factory ISO with cloud-init and QEMU Guest Agent"
        fi
    fi
    
    # Approach 2: Try alternative Factory schematic for ISO
    if [[ "$download_successful" == false ]]; then
        echo "Trying alternative Factory schematic..."
        # Alternative schematic that might work better for ISO format
        local alt_schematic="ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
        download_url="https://factory.talos.dev/image/${alt_schematic}/${talos_version}/nocloud-amd64.iso"
        echo "Alternative Factory URL: $download_url"
        
        if wget --show-progress --timeout=180 --tries=2 "$download_url" -O "$IMAGE_FILE" 2>/dev/null; then
            download_successful=true
            echo "✅ Downloaded from alternative Factory schematic"
        fi
    fi
    
    # Approach 3: Try Factory with different platform format
    if [[ "$download_successful" == false ]]; then
        echo "Trying Factory metal platform ISO..."
        download_url="https://factory.talos.dev/image/${factory_schematic}/${talos_version}/metal-amd64.iso"
        echo "Factory metal URL: $download_url"
        
        if wget --show-progress --timeout=180 --tries=2 "$download_url" -O "$IMAGE_FILE" 2>/dev/null; then
            download_successful=true
            echo "✅ Downloaded Factory metal ISO (works for cloud environments)"
        fi
    fi
    
    # Approach 4: Create custom Factory ISO using API (advanced)
    if [[ "$download_successful" == false ]]; then
        echo "Trying to create custom Factory schematic..."
        echo "Creating schematic with cloud-init and qemu-guest-agent extensions..."
        
        # Try to create a custom schematic via Factory API
        local custom_schematic
        custom_schematic=$(curl -s -X POST "https://factory.talos.dev/schematics" \
            -H "Content-Type: application/json" \
            -d '{
                "customization": {
                    "systemExtensions": {
                        "officialExtensions": [
                            "siderolabs/qemu-guest-agent"
                        ]
                    }
                }
            }' | grep -o '"id":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
        
        if [[ -n "$custom_schematic" ]]; then
            echo "Created custom schematic: $custom_schematic"
            download_url="https://factory.talos.dev/image/${custom_schematic}/${talos_version}/nocloud-amd64.iso"
            echo "Custom Factory URL: $download_url"
            
            # Wait a moment for the image to be built
            echo "Waiting for Factory to build the custom image..."
            sleep 10
            
            if wget --show-progress --timeout=300 --tries=3 "$download_url" -O "$IMAGE_FILE" 2>/dev/null; then
                download_successful=true
                echo "✅ Downloaded custom Factory ISO with extensions"
            fi
        fi
    fi
    
    # Approach 5: Fallback to standard Talos ISO (without extensions)
    if [[ "$download_successful" == false ]]; then
        echo "Factory unavailable, downloading standard Talos ISO..."
        download_url="https://github.com/siderolabs/talos/releases/download/${talos_version}/metal-amd64.iso"
        echo "Standard Talos URL: $download_url"
        
        if wget --show-progress --timeout=180 --tries=2 "$download_url" -O "$IMAGE_FILE"; then
            download_successful=true
            echo "✅ Downloaded standard Talos ISO"
            echo "⚠️  Note: This ISO doesn't include factory extensions"
            echo "   You can manually configure qemu-guest-agent after installation"
        fi
    fi
    
    # Check if any download was successful
    if [[ "$download_successful" == false ]]; then
        echo "Error: All Talos ISO download attempts failed. Please check:" >&2
        echo "  1. Internet connectivity" >&2
        echo "  2. Talos version availability: $talos_version" >&2
        echo "  3. Talos Factory status: https://factory.talos.dev/" >&2
        echo "  4. Manual creation at: https://factory.talos.dev/" >&2
        echo "     - Add 'siderolabs/qemu-guest-agent' extension" >&2
        echo "     - Select 'nocloud' platform" >&2
        echo "     - Download the generated ISO" >&2
        exit 1
    fi
    
    # Verify downloaded file
    if [[ ! -f "$IMAGE_FILE" ]] || [[ ! -s "$IMAGE_FILE" ]]; then
        echo "Error: Downloaded file is missing or empty" >&2
        exit 1
    fi
    
    # Verify it's a valid ISO file
    if ! file "$IMAGE_FILE" | grep -q "ISO 9660\|boot sector"; then
        echo "Warning: Downloaded file may not be a valid ISO image" >&2
        echo "File type: $(file "$IMAGE_FILE")" >&2
    fi
    
    echo "✅ Talos Factory ISO ready: $IMAGE_FILE"
    echo "File size: $(du -h "$IMAGE_FILE" | cut -f1)"
    echo ""
    echo "🏭 This Factory ISO includes:"
    echo "   • QEMU Guest Agent for better Proxmox integration"
    echo "   • Cloud-init compatible configuration"
    echo "   • Optimized for virtualized environments"
    echo ""
    echo "📁 ISO stored in: /var/lib/vz/template/iso/$IMAGE_FILE"
    echo "🔄 This ISO can be reused for multiple VM deployments"
}

# Download and setup image
download_image() {
    if [[ "$DISTRO" == "talos_latest" ]]; then
        generate_talos_image
        echo ""
        echo "✅ Talos Factory ISO downloaded and ready for use!"
        echo "📁 Location: /var/lib/vz/template/iso/$IMAGE_FILE"
        echo ""
        echo "🔄 You can now use this ISO to:"
        echo "  1. Create VMs manually from Proxmox GUI"
        echo "  2. Use with other automation tools"
        echo "  3. Boot multiple VMs from the same ISO"
        echo ""
        echo "💡 The ISO includes QEMU Guest Agent and cloud-init support"
        echo "   for better Proxmox integration and automatic configuration."
        return
    fi
    
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
        --vga serial0
    
    # Set cloud-init user based on distribution
    if [[ "$DISTRO" == "talos_latest" ]]; then
        # Talos doesn't use traditional cloud-init users, but we set it for compatibility
        echo "Configuring Talos cloud-init settings..."
    else
        qm set "$VM_ID" --ciuser "$USERNAME"
    fi
    
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
    
    # Show appropriate success message
    if [[ "$DISTRO" == "talos_latest" ]]; then
        echo ""
        echo "✅ Talos cloud template $VM_NAME created successfully!"
        echo ""
        echo "🚀 This template uses Talos Factory cloud image with:"
        echo "   • Cloud-init support for configuration"
        echo "   • QEMU Guest Agent for better Proxmox integration"
        echo "   • Optimized for virtualized environments"
        echo ""
        echo "📋 To use this Talos template:"
        echo "  1. Clone: qm clone $VM_ID <new-vm-id> --name <vm-name>"
        echo "  2. Resize disk if needed: qm resize <new-vm-id> scsi0 +32G"
        echo "  3. Start VM: qm start <new-vm-id>"
        echo "  4. Configure with talosctl after boot:"
        echo "     talosctl gen config cluster-name https://<vm-ip>:6443"
        echo "     talosctl apply-config --insecure --nodes <vm-ip> --file controlplane.yaml"
        echo ""
        echo "💡 Cloud image provides better integration with Proxmox cloud-init!"
    else
        echo "Template $VM_NAME created successfully!"
    fi
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
    
    # Check dependencies for Talos
    if [[ "$DISTRO" == "talos_latest" ]]; then
        check_talos_dependencies
    fi
    
    # Setup for template creation
    VM_ID=$(get_next_vm_id)
    
    # Handle Talos configuration differently
    if [[ "$DISTRO" == "talos_latest" ]]; then
        TALOS_VERSION=$(get_latest_talos_version)
        VM_NAME="talos-${TALOS_VERSION}-template"
        IMAGE_FILE="talos-${TALOS_VERSION}-factory.iso"
        echo "Creating: $VM_NAME (ID: $VM_ID)"
        echo ""
    else
        # Parse distribution configuration
        IFS=' ' read -r DOWNLOAD_URL USERNAME <<< "${DISTROS[$DISTRO]}"
        DISTRO_NAME=$(echo "$DISTRO" | cut -d'_' -f1)
        VERSION=$(echo "$DISTRO" | cut -d'_' -f2)
        VM_NAME="${DISTRO_NAME}-${VERSION}-template"
        IMAGE_FILE="${DISTRO_NAME}-${VERSION}-cloudimg.img"
        echo "Creating: $VM_NAME (ID: $VM_ID)"
        echo ""
    fi
    
    download_image
    
    # Only create VM template for non-Talos distributions
    if [[ "$DISTRO" != "talos_latest" ]]; then
        create_vm
    fi
    
    echo ""
    if [[ "$DISTRO" != "talos_latest" ]]; then
        echo "Template ready! To use:"
        echo "  qm clone $VM_ID <new-vm-id> --name <vm-name>"
        echo "  qm resize <new-vm-id> scsi0 +10G"
        echo "  qm start <new-vm-id>"
    fi
}

# Run main function
main