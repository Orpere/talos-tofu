
output "talos_k8s_details" {
  value = <<-EOT
PlEASE FEEL FREE TO GET YOUR CLUSTER DETAILS BELOW:

   Control plane IP: ${module.talos-proxmox.control_plane_info[0].ip}
   Kubeconfig path: ${path.cwd}/${module.cluster-talos.kubeconfig}
   Talos configuration path: ${module.cluster-talos.talosconfig}
   Cluster name: ${module.talos-proxmox.cluster_name}
   Worker IPs: ${join(",", [for obj in module.talos-proxmox.worker_info : obj.ip])}
   Control Plane IPs: ${join(",", [for obj in module.talos-proxmox.control_plane_info : obj.ip])}

To access your Kubernetes cluster, run:
   export KUBECONFIG=${path.cwd}/${module.cluster-talos.kubeconfig}
   kubectl get nodes

To use the dns you have config your A records are:
${join("\n   ", [for name, addresses in module.dns.dns_a_records : "${name}.${module.talos-proxmox.prox_domain} -> ${join(", ", addresses)}"])} 
EOT
}

