

resource "null_resource" "check_and_install" {
  count = length(var.packages)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<EOT
      PACKAGE=${var.packages[count.index]}
      echo "Checking if $PACKAGE is installed..."

      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS check
        if ! command -v $PACKAGE >/dev/null 2>&1; then
          echo "$PACKAGE not found, installing with brew..."
          brew install $PACKAGE
        else
          echo "$PACKAGE is already installed."
        fi
      elif [[ -f /etc/debian_version ]]; then
        # Ubuntu/Debian check
        if ! dpkg -s $PACKAGE >/dev/null 2>&1; then
          echo "$PACKAGE not found, installing with apt..."
          sudo apt-get update && sudo apt-get install -y $PACKAGE
        else
          echo "$PACKAGE is already installed."
        fi
      else
        echo "Unsupported OS: $OSTYPE"
      fi
    EOT
  }
}
