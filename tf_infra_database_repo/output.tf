output "postgres_cluster_name" {
  value = "postgres-ha-cluster"
}

output "postgres_namespace" {
  value = kubernetes_namespace.cloudnative_pg_namespace.metadata[0].name
}

output "longhorn_storage_class" {
  value = kubernetes_storage_class_v1.longhorn_ha.metadata[0].name
}