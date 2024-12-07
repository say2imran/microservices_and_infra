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
  version          = "1.6.0"

  values = [
    yamlencode({
      persistence = {
        defaultClass = true
        defaultClassReplicaCount = 3  # Minimum 3 replicas across different nodes
      }
      
      longhornManager = {
        priorityClass = "system-cluster-critical"
      }
      
      # Tolerations for dedicated storage nodes
      tolerations = [
        {
          key = "dedicated"
          operator = "Equal"
          value = "storage"
          effect = "NoSchedule"
        }
      ]
      
      # Backup Configuration
      defaultSettings = {
        backupTarget = "s3://your-longhorn-backups/backups"
        backupTargetCredentialSecret = "longhorn-backup-credentials"
      }
    })
  ]
}

# High Availability Longhorn StorageClass
resource "kubernetes_storage_class_v1" "longhorn_ha" {
  metadata {
    name = "longhorn-ha"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
  
  storage_provisioner = "driver.longhorn.io"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    "numberOfReplicas" = "3"
    "staleReplicaTimeout" = "2880"  # 48 hours
    "dataLocality" = "best-effort"
    "fsType" = "ext4"
    
    # Topology Spread Configurations
    "diskSelector" = ""
    "nodeSelector" = ""
    "tags" = "ha-postgres"
  }
}

# CloudNativePG Namespace
resource "kubernetes_namespace" "cloudnative_pg_namespace" {
  metadata {
    name = "cloudnative-pg"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "high-availability" = "true"
    }
  }
}

# CloudNativePG Operator with HA Configuration
resource "helm_release" "cloudnative_pg_operator" {
  name       = "cloudnative-pg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.20.0"
  namespace  = kubernetes_namespace.cloudnative_pg_namespace.metadata[0].name

  values = [
    yamlencode({
      # Operator High Availability
      replicaCount = 3
      
      # Distributed Deployment
      topologySpreadConstraints = [
        {
          maxSkew = 1
          topologyKey = "topology.kubernetes.io/zone"
          whenUnsatisfiable = "DoNotSchedule"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = "cloudnative-pg"
            }
          }
        }
      ]
      
      # Enhanced Monitoring
      monitoring = {
        enabled = true
        prometheus = {
          podMonitor = {
            enabled = true
          }
        }
      }
    })
  ]

  depends_on = [helm_release.longhorn]
}

# High Availability PostgreSQL Cluster
resource "kubernetes_manifest" "postgres_ha_cluster" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Cluster"
    metadata = {
      name = "postgres-ha-cluster"
      namespace = kubernetes_namespace.cloudnative_pg_namespace.metadata[0].name
      labels = {
        "high-availability" = "true"
        "cluster-purpose" = "production"
      }
    }
    spec = {
      # High Availability Configuration
      instances = 3  # Minimum 3 instances for quorum-based HA
      
      # Advanced HA Topology
      affinity = {
        enablePodAntiAffinity = true
        topologyKey = "topology.kubernetes.io/zone"
      }
      
      # Persistent Storage Configuration
      storage = {
        storageClass = kubernetes_storage_class_v1.longhorn_ha.metadata[0].name
        size = "100Gi"
      }
      
      # PostgreSQL Enhanced Configuration
      postgresql = {
        parameters = {
          # Performance and HA Tuning
          max_connections = "300"
          shared_buffers = "1GB"
          effective_cache_size = "3GB"
          max_wal_size = "2GB"
          min_wal_size = "1GB"
          
          # Replication and Failover Configurations
          hot_standby = "on"
          max_standby_streaming_delay = "30s"
          wal_receiver_status_interval = "10s"
          wal_persist_past_promotion = "on"
        }
      }
      
      # Comprehensive Backup Strategy
      backup = {
        barmanObjectStore = {
          destinationPath = "s3://to-be-created/cluster"
          s3Credentials = {
            inheritFromIAMRole = true
          }
          wal = {
            compression = "gzip"
            maxParallel = 2
          }
        }
        retentionPolicy = "30d"
        
        # Continuous Backup Configuration
        volumeSnapshot = {
          className = "longhorn-snapshot"
          retentionPolicy = "7d"
        }
      }
      
      # Monitoring and Observability
      monitoring = {
        enablePodMonitor = true
        # Optional: Custom metrics endpoint
        customQueries = [
          {
            name = "pg_custom_connections"
            query = "pg_stat_activity_count"
          }
        ]
      }
      
      # Failover and Switchover Configurations
      failoverDelay = 30
      switchoverDelay = 30
    }
  }

  depends_on = [
    helm_release.cloudnative_pg_operator,
    kubernetes_storage_class_v1.longhorn_ha
  ]
}

# Optional: Cluster-wide Pod Disruption Budget
resource "kubernetes_manifest" "postgres_pdb" {
  manifest = {
    apiVersion = "policy/v1"
    kind = "PodDisruptionBudget"
    metadata = {
      name = "postgres-ha-pdb"
      namespace = kubernetes_namespace.cloudnative_pg_namespace.metadata[0].name
    }
    spec = {
      minAvailable = 2  # Ensure at least 2 pods are always available
      selector = {
        matchLabels = {
          "high-availability" = "true"
        }
      }
    }
  }
}

