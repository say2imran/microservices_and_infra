resource "helm_release" "jaeger" {
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = var.namespace
  version    = "0.71.0"

  values = [<<EOF
allInOne:
  enabled: false

collector:
  enabled: true
  replicaCount: 3
  service:
    type: ClusterIP

query:
  enabled: true
  service:
    type: ClusterIP
  ingress:
    enabled: true
    hosts:
      - jaeger.${var.domain}

storage:
  type: elasticsearch
  options:
    es:
      server-urls: http://elasticsearch:9200
EOF
  ]
}
