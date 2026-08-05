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

  ecs_tags = {
    resource = "ecs-cluster"
    service  = var.ecs_name
  }
}