
resource "null_resource" "helm_charts" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export KUBECONFIG=${path.cwd}/clusters_configs/${var.name}/kubeconfig

      # Install a Helm chart (example: nginx-ingress)
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo update
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
    EOT
  }
  depends_on = [null_resource.wait_for_k8s_nodes]
}

resource "null_resource" "kustomize_apps" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export KUBECONFIG=${path.cwd}/clusters_configs/${var.name}/kubeconfig

      # Apply a Kubernetes manifest

      kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
      command sleep 60
      # on folder manifests
      # you can put your kustomize manifests
      # or kubernetes manifests 
      kubectl apply -f manifests/

    EOT
  }
  depends_on = [null_resource.wait_for_k8s_nodes]
}