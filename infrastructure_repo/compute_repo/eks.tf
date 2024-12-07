provider "aws" {
  region = "us-west-2" 
}

# VPC Module with Single NAT Gateway Disabled
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name            = "eks-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"] # High Availability across AZs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway         = true
  single_nat_gateway         = false
  ## Disabling Single NAT for High availability
  enable_dns_hostnames       = true
  enable_dns_support         = true
  create_igw                 = true
}

# EKS Cluster Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.0.1"

  cluster_name    = "high-availability-eks"
  cluster_version = "1.26"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    ha_nodes = {
      capacity_type  = "ON_DEMAND"
      desired_capacity = 3 
      min_size         = 3
      max_size         = 10
      instance_type    = "t3.medium"

      # Spread nodes across AZs for HA
      availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

      # Add rolling update configuration
      update_config = {
        max_unavailable_percentage = 25 # Allow up to 25% of nodes to be unavailable during updates
      }

      additional_tags = {
        Environment = "production"
      }
    }
  }

  manage_aws_auth = true
}

# Pod Disruption Budget
resource "kubernetes_pod_disruption_budget" "eks_pdb" {
  metadata {
    name      = "eks-ha-pdb"
    namespace = "kube-system"
  }

  spec {
    min_available = 2 # Ensures at least 2 pods remain available
    selector {
      match_labels = {
        app = "aws-node"
      }
    }
  }
}

# AWS Node Termination Handler for SPOT instances
resource "helm_release" "node_termination_handler" {
  name       = "aws-node-termination-handler"
  chart      = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"

  values = [
    <<EOF
    enableSpotInterruptionDraining: true
    enableScheduledEventDraining: true
    enableRebalanceDraining: true
    nodeSelector:
      lifecycle: "ec2-spot" # Target spot instances
    EOF
  ]
}

