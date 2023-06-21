terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      version = ">= 3.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  }

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
