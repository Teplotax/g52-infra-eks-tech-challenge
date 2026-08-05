output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "app_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "keycloak_repository_url" {
  value = aws_ecr_repository.keycloak.repository_url
}