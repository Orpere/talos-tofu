

resource "null_resource" "check_and_install" {
  count = length(var.packages)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      PACKAGE="${var.packages[count.index]}"
      echo "Checking if $PACKAGE is installed..."

      # Map package names for different systems
      declare -A brew_packages=(
        ["argocd"]="argocd"
        ["kustomize"]="kustomize"
        ["talosctl"]="siderolabs/tap/talosctl"
        ["helmfile"]="helmfile"
      )

      declare -A apt_packages=(
        ["argocd"]="argocd"
        ["kustomize"]="kustomize"
        ["talosctl"]="talosctl"
        ["helmfile"]="helmfile"
      )

      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS check
        # First ensure Homebrew is installed
        if ! command -v brew >/dev/null 2>&1; then
          echo "Homebrew not found. Installing Homebrew first..."
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Use mapped package name if available, otherwise use original
        BREW_PACKAGE="$${brew_packages[$PACKAGE]:-$PACKAGE}"
        
        if ! command -v $PACKAGE >/dev/null 2>&1; then
          echo "$PACKAGE not found, installing with brew..."
          if ! brew install $BREW_PACKAGE; then
            echo "ERROR: Failed to install $PACKAGE via brew"
            exit 1
          fi
        else
          echo "$PACKAGE is already installed."
        fi
      elif [[ -f /etc/debian_version ]]; then
        # Ubuntu/Debian check
        APT_PACKAGE="$${apt_packages[$PACKAGE]:-$PACKAGE}"
        
        if ! command -v $PACKAGE >/dev/null 2>&1; then
          echo "$PACKAGE not found, installing with apt..."
          if ! sudo apt-get update -qq; then
            echo "ERROR: Failed to update package list"
            exit 1
          fi
          if ! sudo apt-get install -y $APT_PACKAGE; then
            echo "ERROR: Failed to install $PACKAGE via apt"
            exit 1
          fi
        else
          echo "$PACKAGE is already installed."
        fi
      elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS/Fedora check
        if ! command -v $PACKAGE >/dev/null 2>&1; then
          echo "$PACKAGE not found, installing with dnf/yum..."
          if command -v dnf >/dev/null 2>&1; then
            if ! sudo dnf install -y $PACKAGE; then
              echo "ERROR: Failed to install $PACKAGE via dnf"
              exit 1
            fi
          elif command -v yum >/dev/null 2>&1; then
            if ! sudo yum install -y $PACKAGE; then
              echo "ERROR: Failed to install $PACKAGE via yum"
              exit 1
            fi
          else
            echo "ERROR: No suitable package manager found for RHEL-based system"
            exit 1
          fi
        else
          echo "$PACKAGE is already installed."
        fi
      else
        echo "ERROR: Unsupported OS: $OSTYPE"
        echo "Supported systems: macOS, Debian/Ubuntu, RHEL/CentOS/Fedora"
        exit 1
      fi
    EOT
  }
}
