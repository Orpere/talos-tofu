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
      
      # Execute commands sequentially with proper error handling
      echo "Step 1/8: Applying MetalLB manifest..."
      kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
      sleep 60
      
      echo "Step 2/8: Applying CRDs..."
      kubectl apply -f apps/manifests/crds/
      sleep 60
      
      echo "Step 3/8: Creating ArgoCD namespace..."
      kubectl create namespace argocd || true
      sleep 60

      echo "Step 3.1/8: Creating openbao namespace..."
      kubectl create namespace openbao || true
      sleep 10

      echo "Step 4/8: Applying overlays..."
      kubectl apply -f apps/manifests/overlays/
      sleep 60
      
      echo "Step 5/8: Creating RFC2136 keys secret..."
      kubectl create secret generic rfc2136-keys --from-literal=rfc2136-tsig-secret='${var.tsig_secret}' --from-literal=rfc2136-tsig-keyname='${var.tsig_keyname}' -n external-dns
      sleep 60
      
      echo "Step 6/8: Creating Cloudflare API token secret..."
      kubectl create secret generic cloudflare-api-token-secret --from-literal=api-token=${var.cloudflare_api_token} -n cert-manager
      sleep 60
      
      echo "Step 7/8: Installing ArgoCD..."
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      sleep 60
      
      echo "Step 8/8: Extracting ArgoCD admin password..."
      # Wait for the secret to be created
      echo "Waiting for ArgoCD initial admin secret to be available..."
      kubectl wait --for=condition=Ready --timeout=300s pod -l app.kubernetes.io/name=argocd-server -n argocd
      
      # Wait for the secret to exist with retry loop
      echo "Waiting for argocd-initial-admin-secret to be created..."
      for i in {1..30}; do
        if kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; then
          echo "Secret found! Extracting password..."
          break
        fi
        echo "Attempt $i/30: Secret not found yet, waiting 10 seconds..."
        sleep 10
      done
      
      # Final check and extract the password
      # if kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; then
      #   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d > ${path.cwd}/clusters_configs/${var.name}/argocd_password.txt
      #   echo "ArgoCD admin password saved to ${path.cwd}/clusters_configs/${var.name}/argocd_password.txt"
      # else
      #   echo "Error: ArgoCD initial admin secret still not found after 5 minutes. Something may be wrong with the ArgoCD installation."
      #   exit 1
      # fi

      echo "Step 9/8: Applying additional manifests..."
      kubectl apply -f apps/manifests/ingress/
      sleep 60
      
      echo "All commands completed successfully!"
    EOT
  }
  triggers = {
    all_apps_hash = md5(join("", [for f in fileset(path.module, "apps/**") : filemd5("${path.module}/${f}")]))
  }
  depends_on = [null_resource.wait_for_k8s_nodes]
}
