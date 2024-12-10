resource "helm_release" "thanos" {
  name       = "thanos"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "thanos"
  namespace  = var.namespace
  version    = "12.5.1"

  values = [<<EOF
query:
  enabled: true
  replicaCount: 2
  ingress:
    enabled: true
    hostname: thanos.${var.domain}
  stores:
    - dnssrv+_grpc._tcp.prometheus-thanos-sidecar.${var.namespace}.svc.cluster.local

queryFrontend:
  enabled: true
  replicaCount: 2
  ingress:
    enabled: true
    hostname: thanos-frontend.${var.domain}

bucketweb:
  enabled: true
  ingress:
    enabled: true
    hostname: thanos-bucket.${var.domain}

compactor:
  enabled: true
  retentionResolutionRaw: 30d
  retentionResolution5m: 60d
  retentionResolution1h: 90d
  persistence:
    enabled: true
    size: 8Gi

storegateway:
  enabled: true
  replicaCount: 2
  persistence:
    enabled: true
    size: 8Gi

ruler:
  enabled: true
  replicaCount: 2
  persistence:
    enabled: true
    size: 8Gi

receive:
  enabled: true
  replicaCount: 2
  persistence:
    enabled: true
    size: 8Gi

objstoreConfig:
  secretName: thanos-objstore-config
  secretKey: objstore.yml

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
EOF
  ]

  depends_on = [kubernetes_secret.thanos_objstore]
}

resource "kubernetes_secret" "thanos_objstore" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = var.namespace
  }

  data = {
    "objstore.yml" = yamlencode({
      type: "s3"
      config: {
        bucket: var.s3_bucket
        endpoint: "s3.${var.s3_region}.amazonaws.com"
        region: var.s3_region
        access_key: var.objstore_config["access_key"]
        secret_key: var.objstore_config["secret_key"]
      }
    })
  }
}
