environment           = "dev"
cluster_name          = "eks-tech-challenge"
kubernetes_version    = "1.34"
vpc_id                = "vpc-070d1017834697b0d"
public_subnet_ids     = ["subnet-0ce22c7ae42161e3b", "subnet-0e7519432685ea166"]
private_subnet_cidrs  = ["172.31.64.0/20", "172.31.80.0/20"]
app_namespace         = "tech-challenge"
destroy               = false
