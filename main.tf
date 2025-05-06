module "talos-proxmox" {
  source = "./talos-proxmox"
  # Cluster configuration
  name = "talos"

  # Control Plane Configuration
  cp_count     = 1
  cp_cores     = 4
  cp_memory    = 2048 # in MB
  cp_disk_size = 80   # in GB

  # Worker Node Configuration
  worker_count     = 1
  worker_cores     = 8
  worker_memory    = 8196 # in MB
  worker_disk_size = 100  # in GB
}

output "control-planes" {
  value = module.talos-proxmox.control_plane_info
}

output "workers" {
    value = module.talos-proxmox.worker_info
}