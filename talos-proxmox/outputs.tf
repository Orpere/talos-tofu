
output "control_plane_info" {
  value = [
    for vm in proxmox_vm_qemu.control-plane :
    {
      ip = vm.default_ipv4_address
      # or whatever attribute holds the IP
    }
  ]
}

output "worker_info" {
  value = [
    for vm in proxmox_vm_qemu.worker :
    {
      ip = vm.default_ipv4_address
      # or whatever attribute holds the IP
    }
  ]
}

output "cluster_name" {
  value = var.name
}

output "worker_ips" {
  value = var.worker_ips
}
output "control_plane_ips" {
  value = var.control_planes_ips
}

output "prox_domain" {
  value = var.prox_domain
}