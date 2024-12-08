output "cluster_name" {
  value = module.eks.cluster_id
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "node_group_role_arn" {
  value = module.eks.node_groups["ha_nodes"].iam_role_arn
}
