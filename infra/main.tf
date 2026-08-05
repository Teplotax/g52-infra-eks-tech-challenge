resource "aws_ecs_cluster" "main" {
  name = var.ecs_name
  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }
  tags = local.ecs_tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecr_repository" "app" {
  name = "grupo52/tech-challenge/${var.ecs_name}"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecr_repository" "keycloak" {
  name = "grupo52/tech-challenge/${var.ecs_name}-keycloak"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }
}