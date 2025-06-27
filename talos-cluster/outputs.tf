
output "kubeconfig" {
  value     = data.talos_client_configuration.main
  sensitive = true
}