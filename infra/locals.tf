locals {
  project = "tech-challenge"
  squad   = "grupo-52"
  sigla   = "g52"

  common_tags = {
    environment = var.environment
    squad       = local.squad
    sigla       = local.sigla
    project     = local.project
  }

  cluster_tags = merge(local.common_tags, {
    resource = "eks-cluster"
    service  = var.cluster_name
  })
}
