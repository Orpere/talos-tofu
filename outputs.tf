
output "talos_k8s_details" {
  value = templatefile("cluster-info.tpl", {
    control_plane_ip  = module.talos-proxmox.control_plane_info[0].ip
    kubeconfig_path   = "${path.cwd}/${module.cluster-talos.kubeconfig}"
    talosconfig_path  = module.cluster-talos.talosconfig
    cluster_name      = module.talos-proxmox.cluster_name
    worker_ips        = join(",", [for obj in module.talos-proxmox.worker_info : obj.ip])
    control_plane_ips = join(",", [for obj in module.talos-proxmox.control_plane_info : obj.ip])
    dns_records = join("\n", [
      for name, addresses in module.dns.dns_a_records :
      "${name}.${module.talos-proxmox.prox_domain} -> ${join(", ", addresses)}"
    ])
  })
}