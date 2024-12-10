resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = var.namespace
  version    = "6.52.4"

  values = [<<EOF
persistence:
  enabled: true
  size: 5Gi

ingress:
  enabled: true
  hosts:
    - grafana.${var.domain}

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://${var.prometheus_host}:80
      access: proxy
      isDefault: true
    - name: Thanos
      type: prometheus
      url: http://thanos-query:9090
      access: proxy
    - name: Jaeger
      type: jaeger
      url: http://${var.jaeger_host}:16686
      access: proxy

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default
EOF
  ]
}
