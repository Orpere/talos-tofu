
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