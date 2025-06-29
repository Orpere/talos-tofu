# Talos Kubernetes Cluster on Proxmox with OpenTofu

This project provisions a Talos-based Kubernetes cluster on Proxmox VMs using [OpenTofu](https://opentofu.org/) (Terraform fork).  
It also manages DNS records for your cluster nodes.

---

## Project Structure

- **main.tf** – Root OpenTofu configuration, wiring all modules together.
- **talos-proxmox/** – Proxmox VM provisioning for control plane and worker nodes.
- **tofu-dns/** – DNS record management for cluster nodes.
- **cluster-talos/** – Talos cluster bootstrapping and configuration.

---

## Requirements

- [OpenTofu](https://opentofu.org/) or Terraform
- [Proxmox](https://www.proxmox.com/) cluster with API access
- [talosctl](https://www.talos.dev/docs/latest/introduction/what-is-talos/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally
- DNS server supporting dynamic updates (RFC2136)
- SSH access to Proxmox nodes

---

## Setting Up a `.env` File for Inputs

You can create a `.env` file to store required input variables for your OpenTofu deployment.  
This helps keep secrets and configuration out of your main files and makes automation easier.

### Example `.env` file

```env
# Proxmox credentials
PM_API_URL=https://your-proxmox-host:8006/api2/json
PM_USER=root@pam
PM_PASS=your_proxmox_password

# DNS credentials
DNS_SERVER=192.168.0.254
KEY_ALGORITHM=hmac-sha512
KEY_NAME=example.com.
ZONE=example.com.
KEY_SECRET=your_dns_key_secret

# Cluster settings
CLUSTER_NAME=talos-cluster
```

### How to use the `.env` file

1. Copy the example above to a file named `.env` in your project root.
2. Export the variables before running OpenTofu:

   ```sh
   set -a
   source .env
   set +a
   ```

3. Reference these environment variables in your `terraform.tfvars` or directly in your module blocks using `${env.VAR_NAME}` syntax if supported, or let your provider/module pick them up from the environment.

**Tip:**  
Never commit your `.env` file to version control if it contains secrets. Add `.env` to your `.gitignore`.

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

   - Create a `terraform.tfvars` file or set variables via CLI/environment.
   - Example for secrets:
     ```hcl
     key_secret = "your_dns_key_secret"
     ```

4. **Apply the configuration**

   ```sh
   tofu apply
   ```

5. **Access your cluster**

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

## Outputs

- **talos_k8s_details**: Full cluster access instructions and details (see above).
- **kubeconfig**: Absolute path to your generated kubeconfig.
- **talosconfig**: Path to your Talos configuration directory.

---

## Notes

- Ensure your Proxmox and DNS credentials are set correctly.
- The cluster will not be accessible until all Talos steps complete.
- You may need to manually create the `clusters_configs/` directory before running `tofu apply`.

---

## License

MIT