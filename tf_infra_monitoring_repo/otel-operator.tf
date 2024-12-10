resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = var.namespace
  version    = "0.55.0"

  values = [<<EOF
mode: deployment

config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
    
    prometheus:
      config:
        scrape_configs:
          - job_name: 'otel-collector'
            scrape_interval: 10s
            static_configs:
              - targets: ['prometheus-server:9090']

  processors:
    batch:
      timeout: 1s
      send_batch_size: 1024
    
    memory_limiter:
      check_interval: 1s
      limit_mib: 1024
      spike_limit_mib: 128

  exporters:
    prometheus:
      endpoint: "0.0.0.0:8889"
    
    jaeger:
      endpoint: "jaeger-collector:14250"
      tls:
        insecure: true
    
    logging:
      verbosity: detailed

  service:
    pipelines:
      traces:
        receivers: [otlp, jaeger]
        processors: [memory_limiter, batch]
        exporters: [jaeger, logging]
      
      metrics:
        receivers: [otlp, prometheus]
        processors: [memory_limiter, batch]
        exporters: [prometheus, logging]
EOF
  ]
}
