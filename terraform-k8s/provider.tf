provider "kubernetes" {
  config_path = "~/.kube/config"
}
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.1"
    }
  }
}
