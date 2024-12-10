terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
  }
}

resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  create_namespace = true
  version          = "1.6.0"  # Check for the latest version

  values = [
    yamlencode({
      # Longhorn configuration
      persistence = {
        defaultClass = true
        defaultClassReplicaCount = 3  # Recommended for HA
      }
      
      # HA and resource settings
      longhornManager = {
        priorityClass = "system-cluster-critical"
      }
      
    })
  ]
}