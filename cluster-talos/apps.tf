resource "null_resource" "helmfile_apply" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      export KUBECONFIG=${path.cwd}/clusters_configs/${var.name}/kubeconfig
      if ! helm plugin list | grep -q diff; then
        helm plugin install https://github.com/databus23/helm-diff
      fi
      # Install Helmfile  
      helmfile -f apps/helm/helmfile.yaml apply
    EOT
  }
  triggers = {
    all_apps_hash = md5(join("", [for f in fileset(path.module, "apps/**") : filemd5("${path.module}/${f}")]))
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
      kubectl apply -f apps/manifests/crds/
      command sleep 60
      kubectl apply -f apps/manifests/overlays/
      command sleep 60
      kubectl create secret generic rfc2136-keys --from-literal=rfc2136-tsig-secret='${var.tsig_secret}' --from-literal=rfc2136-tsig-keyname='${var.tsig_keyname}' -n external-dns
      kubectl create secret generic cloudflare-api-token-secret --from-literal=api-token=${var.cloudflare_api_token}  -n cert-manager
    EOT
  }
  triggers = {
    all_apps_hash = md5(join("", [for f in fileset(path.module, "apps/**") : filemd5("${path.module}/${f}")]))
  }
  depends_on = [null_resource.wait_for_k8s_nodes]
}
