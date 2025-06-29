output "kubernetes_url" {
  value = "cluster is on https://${var.control_planes_ips[0]}:${var.control_plane_port}"
}

output "kubeconfig" {
  value = "clusters_configs/${var.name}/kubeconfig"
}
output "talosconfig" {
  value = "talos configuration is on clusters_configs/${var.name}"
}