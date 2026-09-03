output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}

output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi.arn
}

output "app_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "keycloak_repository_url" {
  value = aws_ecr_repository.keycloak.repository_url
}
