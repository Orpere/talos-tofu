output "kubernetes_url" {
  value = "cluster is on https:// https://${var.control_planes_ips[0]}:${var.control_plane_port}"
}

output "kubeconfig" {
  value = "kube config is on clusters_configs/${var.name}/kubeconfig"
}