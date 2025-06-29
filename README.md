# Talos Kubernetes Cluster on Proxmox with OpenTofu

This project provisions a Talos-based Kubernetes cluster on Proxmox VMs using [OpenTofu](https://opentofu.org/) (Terraform fork).  
It also manages DNS records for your cluster nodes and automates cluster bootstrapping and application installation.

---

## Project Structure

- **main.tf** – Root OpenTofu configuration, wiring all modules together.
- **talos-proxmox/** – Proxmox VM provisioning for control plane and worker nodes.
- **tofu-dns/** – DNS record management for cluster nodes.
- **cluster-talos/** – Talos cluster bootstrapping, configuration, and app installation.
- **manifests/** – (Optional) Your custom Kubernetes manifests to be applied after cluster setup.

---

## Requirements

- [OpenTofu](https://opentofu.org/) or Terraform
- [Proxmox](https://www.proxmox.com/) cluster with API access
- [talosctl](https://www.talos.dev/docs/latest/introduction/what-is-talos/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally
- [Helm](https://helm.sh/) installed locally
- DNS server supporting dynamic updates (RFC2136)
- SSH access to Proxmox nodes

---

## How to Make This Project Yours

1. **Clone the repository**

   ```sh
   git clone <your-repo-url>
   cd <your-repo>
   ```

2. **Set up your environment variables**

   Create a `.env` file in your project root with your own values:

   ```env
   # Proxmox credentials
   PM_API_URL=https://your-proxmox-host:8006/api2/json
   PM_USER=root@pam
   PM_PASS=your_proxmox_password

   # DNS credentials
   DNS_SERVER=192.168.0.254
   KEY_ALGORITHM=hmac-sha512
   KEY_NAME=your_TSIG. 
   ZONE=example.com.
   KEY_SECRET=your_dns_key_secret

   # Cluster settings
   CLUSTER_NAME=talos-cluster
   ```

   **Tip:** Never commit your `.env` file to version control if it contains secrets. Add `.env` to your `.gitignore`.

3. **Export your environment variables**

   ```sh
   set -a
   source .env
   set +a
   ```

4. **Edit `main.tf` as needed**

   - Adjust VM specs, counts, and module parameters to fit your environment.
   - Update DNS and cluster settings as needed.

5. **Initialize OpenTofu**

   ```sh
   tofu init
   ```

6. **Apply the configuration**

   ```sh
   tofu apply
   ```

---

## What Happens

- **Proxmox VMs** for control plane and worker nodes are created.
- **DNS records** are set for all nodes.
- **Talos cluster** is bootstrapped and configured.
- **Kubernetes manifests** and Helm charts are installed automatically (see `cluster-talos/cluster.tf` and `manifests/`).

---

## Accessing Your Cluster

After a successful apply, you will see an output similar to:

```
PlEASE FEEL FREE TO GET YOUR CLUSTER DETAILS BELOW:

   Control plane IP: 192.168.0.100
   Kubeconfig path: /absolute/path/to/clusters_configs/talos-cluster/kubeconfig
   Talos configuration path: talos configuration is on clusters_configs/talos-cluster
   Cluster name: talos
   Worker IPs: 192.168.0.111,192.168.0.112,192.168.0.113
   Control Plane IPs: 192.168.0.100

To access your Kubernetes cluster, run:
   export KUBECONFIG=/absolute/path/to/clusters_configs/talos-cluster/kubeconfig
   kubectl get nodes
```

---

## Customizing for Your Needs

- **VM specs:** Change CPU, memory, disk, and node counts in `main.tf`.
- **DNS:** Update DNS server, zone, and key info in your `.env` and `main.tf`.
- **Cluster name:** Change the `name` parameter in `main.tf` and `.env`.
- **Manifests:** Place your custom Kubernetes YAML files in the `manifests/` directory to have them applied automatically.
- **Helm charts:** Edit the `install_apps` resource in `cluster-talos/cluster.tf` to install or upgrade any Helm charts you need.

---

## Outputs

- **control_plane_info / worker_info:** Lists of node IPs from Proxmox.
- **cluster_name:** The name of your cluster.
- **worker_ips / control_plane_ips:** Lists of worker and control plane IPs.
- **talos_k8s_details:** Full cluster access instructions and details.

---

## Notes

- Ensure your Proxmox and DNS credentials are set correctly.
- The cluster will not be accessible until all Talos steps complete.
- You may need to manually create the `clusters_configs/` directory before running `tofu apply`.
- All resources are managed via OpenTofu—destroying the stack will remove all VMs and DNS records.

---

## License

MIT