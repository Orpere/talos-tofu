# Scripts Documentation

This directory contains utility scripts for managing the Talos-Tofu infrastructure project.

## Scripts Overview

| Script | Purpose | Status |
|--------|---------|---------|
| `get_bao_keys.sh` | Retrieve OpenBao initialization keys and tokens | ✅ Ready |
| `pve_tpl_creator.sh` | Create Proxmox VM templates from cloud images | ✅ Ready |

---

## � get_bao_keys.sh

A utility script to retrieve OpenBao initialization keys and root token from Kubernetes secrets.

### OpenBao Features

- **Multiple Output Formats**: Table (default), JSON, and YAML
- **Namespace Support**: Retrieve keys from any Kubernetes namespace
- **Error Handling**: Clear error messages and validation
- **Security**: Handles base64-encoded secret data properly

### OpenBao Usage

#### Basic OpenBao Usage

```bash
# Retrieve keys from default namespace in table format
./get_bao_keys.sh
```

#### Advanced OpenBao Usage

```bash
# Specify namespace
./get_bao_keys.sh --namespace openbao

# JSON output format
./get_bao_keys.sh --format json

# YAML output format
./get_bao_keys.sh --format yaml

# Custom secret name
./get_bao_keys.sh --secret my-openbao-keys

# Combined options
./get_bao_keys.sh -n openbao -f json -s openbao-init-keys
```

#### Command Line Options

| Option | Short | Description | Default |
|--------|--------|-------------|---------|
| `--namespace` | `-n` | Kubernetes namespace | `default` |
| `--secret` | `-s` | Secret name containing keys | `openbao-keys` |
| `--format` | `-f` | Output format: table, json, yaml | `table` |
| `--help` | `-h` | Show help message | - |

### Output Examples

#### Table Format (Default)

```text
OpenBao Initialization Keys and Token
Namespace: default
Secret: openbao-keys

Key                  | Value
--------------------+----------------------------------------
Root Token          | hvs.CAESIG7q8...
Unseal Key 0        | MEHh8fbTvd4...
Unseal Key 1        | kKhz2SNkhe8...
```

#### JSON Format

```json
{
  "root_token": "hvs.CAESIG7q8...",
  "unseal_keys": [
    "MEHh8fbTvd4...",
    "kKhz2SNkhe8..."
  ]
}
```

#### YAML Format

```yaml
openbao_init:
  namespace: default
  secret: openbao-keys
  root_token: "hvs.CAESIG7q8..."
  unseal_keys:
    - "MEHh8fbTvd4..."
    - "kKhz2SNkhe8..."
```

### OpenBao Prerequisites

- `kubectl` configured and connected to your Kubernetes cluster
- `jq` for JSON processing
- `base64` decoder (standard on most Unix systems)
- Access to the namespace containing OpenBao secrets

### OpenBao Security Considerations

⚠️ **Important**: This script handles sensitive cryptographic material:

- Ensure proper RBAC is configured for secret access
- Be careful where you redirect output (avoid logs, history)
- Consider using `history -d` to remove commands from shell history
- Use appropriate file permissions if saving to files

### OpenBao Troubleshooting

- **"Secret not found"**: Verify secret name and namespace, check permissions
- **"kubectl not installed"**: Install kubectl using your system's package manager
- **"N/A" values**: Secret might not contain expected keys or keys have different names

---

## 🖥️ pve_tpl_creator.sh

An automated Proxmox VE template creator that builds VM templates from popular Linux distributions and Talos Linux cloud images.

### Proxmox Features

- **Multiple Distributions**: Ubuntu, Debian, Alpine Linux, and Talos Linux
- **Cloud-Init Ready**: All templates support cloud-init for automated configuration
- **Talos Factory Integration**: Downloads optimized Talos images with QEMU Guest Agent
- **SSH Key Integration**: Automatically includes SSH keys from the host
- **Template Management**: Easy cleanup and management of created templates

### Supported Distributions

| Distribution | Versions | Default User | Notes |
|-------------|----------|--------------|-------|
| Ubuntu | 24.04 LTS, 22.04 LTS, 20.04 LTS | ubuntu | Cloud images from Canonical |
| Debian | 12 (Bookworm), 11 (Bullseye) | debian | Official Debian cloud images |
| Alpine | 3.22 | root | Lightweight Alpine Linux |
| Talos | Latest | N/A | Factory-built with extensions |

### Proxmox Usage

#### Basic Proxmox Usage

```bash
# Run the interactive creator (requires root)
sudo ./pve_tpl_creator.sh
```

#### Menu Options

1. **Ubuntu 24.04 LTS** - Latest Ubuntu LTS release
2. **Ubuntu 22.04 LTS** - Previous Ubuntu LTS release  
3. **Ubuntu 20.04 LTS** - Older Ubuntu LTS release
4. **Debian 12** - Latest Debian stable (Bookworm)
5. **Debian 11** - Previous Debian stable (Bullseye)
6. **Alpine 3.22** - Lightweight Alpine Linux
7. **Talos Linux (Latest)** - Container-optimized Talos
8. **Clean all templates and images** - Cleanup option

### Configuration

Default settings (configurable at the top of the script):

```bash
MEMORY=2048          # RAM in MB
CORES=2              # CPU cores
STORAGE="local-lvm"  # Proxmox storage backend
START_VM_ID=9000     # Starting VM ID for templates
```

### Proxmox Prerequisites

- **Proxmox VE** 7.0+ host
- **Root privileges** for VM creation and storage management
- **Internet connectivity** for downloading cloud images
- **Sufficient storage space** (2-10GB per template)
- Required tools (usually pre-installed): `qm`, `wget`, `qemu-img`, `curl`, `jq`

### Template Usage

After creation, use templates with these commands:

```bash
# Clone template to new VM
qm clone <template-id> <new-vm-id> --name <vm-name>

# Resize disk to desired size
qm resize <new-vm-id> scsi0 +20G

# Start the new VM
qm start <new-vm-id>
```

#### Complete Example

```bash
# Clone Ubuntu 24.04 template (assuming template ID 9000)
qm clone 9000 100 --name "web-server-01"

# Resize disk to 32GB total
qm resize 100 scsi0 +20G

# Configure cloud-init settings (optional)
qm set 100 --ipconfig0 ip=192.168.1.100/24,gw=192.168.1.1

# Start the VM
qm start 100
```

### Talos Linux Usage

When selecting Talos, you get a reusable ISO file at:
`/var/lib/vz/template/iso/talos-v1.x.x-factory.iso`

After creating VMs from Talos templates:

```bash
# Generate Talos configuration
talosctl gen config cluster-name https://<vm-ip>:6443

# Apply configuration to node
talosctl apply-config --insecure --nodes <vm-ip> --file controlplane.yaml

# Bootstrap the cluster (on first control plane node)
talosctl bootstrap --nodes <vm-ip>
```

### Cleanup

The script provides a cleanup option (menu option 8) that:

- Removes all VM templates with ID >= 9000
- Deletes associated cloud images
- Confirms action with user prompt

### Proxmox Troubleshooting

#### Common Issues

1. **Permission Denied**: Ensure script is run as root with `sudo`
2. **Storage Full**: Check available space with `df -h /var/lib/vz/`
3. **Network Issues**: Test connectivity to cloud image sources
4. **VM ID Conflicts**: Script automatically finds next available ID >= 9000

#### Talos-Specific Issues

- **Factory Unavailable**: Script tries multiple download methods and falls back to standard ISO
- **Extensions Missing**: Standard ISO doesn't include guest agent, configure manually after installation

### Security Notes

- SSH keys from host `~/.ssh/` are added to templates - review before use
- Templates use bridged networking by default - configure firewall as needed
- Consider VLAN segmentation for isolation in production environments

---

## General Security Notes

- **OpenBao Keys**: Handle sensitive cryptographic material with proper access controls
- **Proxmox Templates**: Review SSH keys and default configurations before production use
- **Root Privileges**: The Proxmox script requires root access for VM management

## Support

For issues or questions:

- Check the troubleshooting sections above
- Verify prerequisites are met
- Consult the main project [README.md](../README.md)

---

*Part of the [Talos-Tofu](../README.md) infrastructure project*
