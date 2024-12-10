resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = var.namespace
  version    = "19.6.1"

  values = [<<EOF
server:
  retention: 6h
  persistentVolume:
    enabled: true
    size: 50Gi
  
  ingress:
    enabled: true
    hosts:
      - prometheus.${var.domain}

  thanos:
    enabled: ${var.thanos_enabled}
    objectStorageConfig:
      secretName: thanos-objstore-config
      secretKey: objstore.yml
    service:
      type: ClusterIP
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi

  extraScrapeConfigs: |
    - job_name: 'otel-collector'
      static_configs:
        - targets: ['otel-collector:8889']

alertmanager:
  enabled: true
  persistentVolume:
    enabled: true
    size: 2Gi

pushgateway:
  enabled: true

nodeExporter:
  enabled: true

serverFiles:
  prometheus.yml:
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
      external_labels:
        cluster: 'main-cluster'
        replica: '$(POD_NAME)'
EOF
  ]

  depends_on = [kubernetes_secret.thanos_objstore]
}

resource "kubernetes_secret" "thanos_objstore" {
  count = var.thanos_enabled ? 1 : 0

  metadata {
    name      = "thanos-objstore-config"
    namespace = var.namespace
  }

  data = {
    "objstore.yml" = yamlencode({
      type: "s3"
      config: {
        bucket: var.objstore_config["bucket"]
        endpoint: "s3.${var.objstore_config["region"]}.amazonaws.com"
        region: var.objstore_config["region"]
        access_key: var.objstore_config["access_key"]
        secret_key: var.objstore_config["secret_key"]
      }
    })
  }
}

