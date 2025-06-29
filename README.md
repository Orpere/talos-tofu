# Talos Cluster on Proxmox with OpenTofu

This project deploys a Talos Kubernetes cluster on Proxmox VMs using [OpenTofu](https://opentofu.org/) (Terraform fork).  
It also configures DNS records for the cluster nodes.

---

## Project Structure

- **talos-proxmox/**: Proxmox VM provisioning for control plane and worker nodes.
- **tofu-dns/**: DNS record management for cluster nodes.
- **cluster-talos/**: Talos cluster bootstrapping and configuration.
- **main.tf**: Root OpenTofu configuration tying everything together.

---

## Requirements

- [OpenTofu](https://opentofu.org/) or Terraform
- [Proxmox](https://www.proxmox.com/) cluster with API access
- [talosctl](https://www.talos.dev/docs/latest/introduction/what-is-talos/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally
- DNS server supporting dynamic updates (RFC2136)
- SSH access to Proxmox nodes

---

## Usage

1. **Clone this repository**

   ```sh
   git clone <your-repo-url>
   cd <your-repo>
   ```

2. **Initialize OpenTofu**

   ```sh
   tofu init
   ```

3. **Set required variables**

   - Create a `terraform.tfvars` or set variables via CLI/environment.
   - Example for secrets:
     ```hcl
     key_secret = "your_dns_key_secret"
     ```

4. **Apply the configuration**

   ```sh
   tofu apply
   ```

5. **Access your cluster**

   - The kubeconfig will be generated in `clusters_configs/<cluster-name>/kubeconfig`.
   - Example:
     ```sh
     export KUBECONFIG=clusters_configs/talos-cluster/kubeconfig
     kubectl get nodes
     ```

---

## Module Overview

### talos-proxmox

- Provisions control plane and worker VMs on Proxmox.
- Outputs node IPs for use in DNS and Talos modules.

### tofu-dns

- Creates DNS records for all cluster nodes using their provisioned IPs.

### cluster-talos

- Bootstraps the Talos cluster.
- Applies Talos configs to all nodes.
- Generates and outputs kubeconfig.

---

## Outputs

- **control_plane_ip**: First control plane node IP
- **control_plane_ips**: Comma-separated list of all control plane IPs
- **worker_ips**: Comma-separated list of all worker node IPs
- **kubeconfig**: Path to generated kubeconfig

---

## Notes

- Ensure your Proxmox and DNS credentials are set correctly.
- The cluster will not be accessible until all Talos steps complete.
- You may need to manually create the `clusters_configs/` directory before running `tofu apply`.

---

## License

MIT