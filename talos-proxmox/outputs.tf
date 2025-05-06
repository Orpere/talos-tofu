# Outputs for the Proxmox cluster setup

output "control_plane_info" {
  value = [
    for i in range(length(proxmox_vm_qemu.control-plane)) :
    "${proxmox_vm_qemu.control-plane[i].name} - ${proxmox_vm_qemu.control-plane[i].default_ipv4_address} - ${proxmox_vm_qemu.control-plane[i].network[0].macaddr}"
  ]
}

output "worker_info" {
  value = [
    for i in range(length(proxmox_vm_qemu.worker)) :
    "${proxmox_vm_qemu.worker[i].name} - ${proxmox_vm_qemu.worker[i].default_ipv4_address} - ${proxmox_vm_qemu.worker[i].network[0].macaddr}"
  ]
}