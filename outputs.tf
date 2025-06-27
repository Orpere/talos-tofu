
output "control_plane_ip" {
  value = module.talos-proxmox.control_plane_info[0].ip
}
output "control_plane_ips" {
  value = join(",", [for obj in module.talos-proxmox.control_plane_info : obj.ip])
}

output "worker_ips" {
  value = join(",", [for obj in module.talos-proxmox.worker_info : obj.ip])
}