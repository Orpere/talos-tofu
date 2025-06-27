output "kubeconfig" {
  value     = talos_cluster_kubeconfig.main.kubeconfig_raw
  description = "Kubeconfig for the Talos cluster"
  sensitive = true
}