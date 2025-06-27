
output "control-planes" {
  value = module.talos-proxmox.control_plane_info
}

output "workers" {
  value = module.talos-proxmox.worker_info
}

output "control_plane_ip" {
  value = module.talos-proxmox.control_plane_info[0].ip
}

output "kubeconfig" {
  value     = module.talos-cluster.kubeconfig
  sensitive = true
}
