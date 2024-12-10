variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "domain" {
  description = "Base domain for ingress"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for Thanos storage"
  type        = string
}

variable "s3_region" {
  description = "AWS region for S3 bucket"
  type        = string
}

variable "objstore_config" {
  description = "Object store configuration for Thanos"
  type        = map(string)
  sensitive   = true
}

