terraform {
  backend "local" {
    path = "clusters_configs/state/terraform.tfstate"
  }
}
