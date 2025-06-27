module "talos-proxmox" {
  source = "./talos-proxmox"
  # Cluster configuration
  name = "talos"

  # Control Plane Configuration
  cp_count     = 3
  cp_cores     = 8
  cp_memory    = 8196 # in MB
  cp_disk_size = 80   # in GB

  # Worker Node Configuration
  worker_count     = 2
  worker_cores     = 8
  worker_memory    = 8196 # in MB
  worker_disk_size = 100  # in GB
}
# DNS Configuration
module "dns" {
  source        = "./tofu-dns"
  dns_server    = "ns.orp-dev.eu"
  key_algorithm = "hmac-sha512"
  key_name      = "orp-dns."
  zone          = "orp-dev.eu."
  key_secret    = var.key_secret

  records = merge(
    { for idx, obj in module.talos-proxmox.control_plane_info : "cp-talos${idx}" => obj.ip },
    { for idx, obj in module.talos-proxmox.worker_info : "worker-talos${idx}" => obj.ip }
  )
}

resource "null_resource" "run_local_script" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -e
      sleep 60 # Wait for Terraform to finish provisioning

      export TALOS_CLUSTER_NAME="${module.talos-proxmox.cluster_name}"
      export TALOS_MANIFESTS_DIR="cluster/${module.talos-proxmox.cluster_name}"

      export CONTROL_PLANE_IP="$(echo "${module.talos-proxmox.control_plane_info[0].ip}" | tr -d ' ')"
      export CONTROL_PLANE_IPS="$(echo "${join(",", [for obj in module.talos-proxmox.control_plane_info : obj.ip])}" | tr -d ' ')"
      export WORKER_IPS="$(echo "${join(",", [for obj in module.talos-proxmox.worker_info : obj.ip])}" | tr -d ' ')"

      echo "Control plane IP: $CONTROL_PLANE_IP"
      echo "Control plane IPs: $CONTROL_PLANE_IPS"
      echo "Worker IPs: $WORKER_IPS"

      ./scripts/install-talos.sh
    EOT
  }
  depends_on = [module.talos-proxmox , module.dns]
}