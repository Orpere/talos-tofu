
# output "control_plane_ip" {
#   value = module.talos-proxmox.control_plane_info[0].ip
# }
# output "control_plane_ips" {
#   value = join(",", [for obj in module.talos-proxmox.control_plane_info : obj.ip])
# }

# output "worker_ips" {
#   value = join(",", [for obj in module.talos-proxmox.worker_info : obj.ip])
# }

# output "kubernetes_url" {
#   value = module.cluster-talos.kubernetes_url
# }

# output "kubeconfig" {
#   value = "${path.cwd}/${module.cluster-talos.kubeconfig}"
# }

# output "talosconfig" {
#   value = module.cluster-talos.talosconfig
# }

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

EOT
}